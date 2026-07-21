pub mod tui;

use anyhow::{anyhow, bail, Context, Result};
use serde::Deserialize;
use serde_json::json;
use std::env;
use std::time::Duration;

pub const DEFAULT_BASE_URL: &str = "http://127.0.0.1:11434";
pub const DEFAULT_MODEL: &str = "qwen2.5-coder:3b";

#[derive(Debug, Clone)]
pub struct ToolCall {
    pub name: String,
    pub arguments: serde_json::Value,
}

fn json_stringish(v: &serde_json::Value) -> Option<String> {
    match v {
        serde_json::Value::String(s) => {
            let t = s.trim();
            if t.is_empty() {
                None
            } else {
                Some(t.to_string())
            }
        }
        // Some small models emit {"type":"string","value":"whoami"}
        serde_json::Value::Object(map) => map
            .get("value")
            .or_else(|| map.get("content"))
            .and_then(json_stringish),
        serde_json::Value::Number(n) => Some(n.to_string()),
        serde_json::Value::Bool(b) => Some(b.to_string()),
        _ => None,
    }
}

impl ToolCall {
    /// Extract a shell command from a `run_shell` / `shell` tool call.
    pub fn shell_command(&self) -> Option<String> {
        let name = self.name.to_ascii_lowercase();
        if !matches!(name.as_str(), "run_shell" | "shell" | "run" | "execute") {
            return None;
        }
        if let Some(s) = self
            .arguments
            .get("command")
            .or_else(|| self.arguments.get("cmd"))
            .and_then(json_stringish)
        {
            return Some(s);
        }
        match &self.arguments {
            serde_json::Value::String(s) => {
                if let Ok(v) = serde_json::from_str::<serde_json::Value>(s) {
                    if let Some(c) = v
                        .get("command")
                        .or_else(|| v.get("cmd"))
                        .and_then(json_stringish)
                    {
                        return Some(c);
                    }
                }
                json_stringish(&serde_json::Value::String(s.clone()))
            }
            _ => None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct ChatMsg {
    pub role: String,
    pub content: String,
    pub tool_calls: Vec<ToolCall>,
}

impl ChatMsg {
    pub fn user(content: impl Into<String>) -> Self {
        Self {
            role: "user".into(),
            content: content.into(),
            tool_calls: Vec::new(),
        }
    }

    pub fn assistant(content: impl Into<String>) -> Self {
        Self {
            role: "assistant".into(),
            content: content.into(),
            tool_calls: Vec::new(),
        }
    }

    pub fn assistant_with_tools(content: impl Into<String>, tool_calls: Vec<ToolCall>) -> Self {
        Self {
            role: "assistant".into(),
            content: content.into(),
            tool_calls,
        }
    }

    pub fn tool_result(content: impl Into<String>) -> Self {
        Self {
            role: "tool".into(),
            content: content.into(),
            tool_calls: Vec::new(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct ChatTurn {
    pub content: String,
    pub tool_calls: Vec<ToolCall>,
}

#[derive(Debug, Deserialize)]
struct TagsResponse {
    #[serde(default)]
    models: Vec<TagModel>,
}

#[derive(Debug, Deserialize)]
struct TagModel {
    name: Option<String>,
    model: Option<String>,
}

#[derive(Debug, Deserialize)]
struct ChatResponse {
    choices: Vec<ChatChoice>,
}

#[derive(Debug, Deserialize)]
struct ChatChoice {
    message: ApiChatMessage,
}

#[derive(Debug, Deserialize)]
struct ApiChatMessage {
    content: String,
}

pub fn base_url() -> String {
    env::var("AI_LOCAL_BASE_URL")
        .or_else(|_| env::var("OLLAMA_HOST"))
        .unwrap_or_else(|_| DEFAULT_BASE_URL.to_string())
        .trim_end_matches('/')
        .to_string()
}

pub fn default_model() -> String {
    env::var("AI_LOCAL_DEFAULT_MODEL").unwrap_or_else(|_| DEFAULT_MODEL.to_string())
}

fn agent() -> ureq::Agent {
    ureq::AgentBuilder::new()
        .timeout_connect(Duration::from_secs(2))
        .timeout_read(Duration::from_secs(300))
        .build()
}

pub fn fetch_model_names(base: &str) -> Result<Vec<String>> {
    let url = format!("{base}/api/tags");
    let resp = agent()
        .get(&url)
        .call()
        .with_context(|| format!("GET {url}"))?;
    let tags: TagsResponse = resp.into_json().context("decode /api/tags")?;
    Ok(tags
        .models
        .into_iter()
        .filter_map(|m| m.name.or(m.model))
        .filter(|n| !n.is_empty())
        .collect())
}

pub fn list_models_numbered(base: &str) -> Result<()> {
    let names = fetch_model_names(base)?;
    if names.is_empty() {
        println!("(none — is ollama running?)");
        return Ok(());
    }
    for (i, name) in names.iter().enumerate() {
        println!("{:2}  {name}", i + 1);
    }
    Ok(())
}

pub fn list_models_raw(base: &str) -> Result<()> {
    for name in fetch_model_names(base)? {
        println!("{name}");
    }
    Ok(())
}

pub fn looks_like_model_spec(s: &str) -> bool {
    s.contains(':') || s.chars().all(|c| c.is_ascii_digit())
}

pub fn resolve_model(base: &str, spec: &str) -> Result<String> {
    if spec.chars().all(|c| c.is_ascii_digit()) {
        let names = fetch_model_names(base)?;
        if names.is_empty() {
            bail!("no models available (is ollama running?)");
        }
        let idx: usize = spec
            .parse()
            .map_err(|_| anyhow!("invalid model index: {spec}"))?;
        if idx < 1 || idx > names.len() {
            eprintln!("error: model index {idx} out of range (1-{})", names.len());
            let _ = list_models_numbered(base);
            bail!("model index out of range");
        }
        return Ok(names[idx - 1].clone());
    }
    Ok(spec.to_string())
}

pub fn chat(base: &str, model: &str, prompt: &str) -> Result<String> {
    chat_messages(base, model, &[ChatMsg::user(prompt)])
}

/// System prompt for interactive TUI (native tools + ```run fallback).
pub const AGENT_SYSTEM_PROMPT: &str = r#"You are a local CLI assistant on the user's machine.
You CAN run shell commands via the run_shell tool.

When you need to execute something, call run_shell with the command.
If tools are unavailable, emit a fenced block instead:

```run
command here
```

Rules:
- Prefer one short command per call.
- Never invent command output — wait for the tool result.
- Do not claim you cannot run commands.
- Avoid destructive commands (rm -rf, mkfs, dd, sudo) unless the user explicitly insists.
- When finished, answer normally with no tool call / run block.
"#;

fn shell_tool_def() -> serde_json::Value {
    json!({
        "type": "function",
        "function": {
            "name": "run_shell",
            "description": "Execute a bash command on the local machine and return stdout/stderr.",
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {
                        "type": "string",
                        "description": "Shell command to run (non-interactive)"
                    }
                },
                "required": ["command"]
            }
        }
    })
}

fn msg_to_api_json(m: &ChatMsg) -> serde_json::Value {
    let mut obj = json!({
        "role": m.role,
        "content": m.content,
    });
    if !m.tool_calls.is_empty() {
        let calls: Vec<_> = m
            .tool_calls
            .iter()
            .map(|t| {
                json!({
                    "type": "function",
                    "function": {
                        "name": t.name,
                        "arguments": t.arguments,
                    }
                })
            })
            .collect();
        obj["tool_calls"] = serde_json::Value::Array(calls);
    }
    obj
}

fn parse_tool_calls(value: &serde_json::Value) -> Vec<ToolCall> {
    let Some(arr) = value.as_array() else {
        return Vec::new();
    };
    let mut out = Vec::new();
    for item in arr {
        let func = item.get("function").unwrap_or(item);
        let name = func
            .get("name")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        if name.is_empty() {
            continue;
        }
        let arguments = match func.get("arguments") {
            Some(serde_json::Value::String(s)) => {
                serde_json::from_str(s).unwrap_or_else(|_| json!({ "command": s }))
            }
            Some(v) => v.clone(),
            None => json!({}),
        };
        out.push(ToolCall { name, arguments });
    }
    out
}

fn merge_content_tools(turn: &mut ChatTurn) {
    // Prefer structured tool_calls; also accept JSON / ```run dumped into content.
    let mut existing: Vec<String> = turn
        .tool_calls
        .iter()
        .filter_map(|t| t.shell_command())
        .collect();
    for cmd in extract_run_commands(&turn.content) {
        if existing.iter().any(|c| c == &cmd) {
            continue;
        }
        turn.tool_calls.push(ToolCall {
            name: "run_shell".into(),
            arguments: json!({ "command": cmd }),
        });
        existing.push(cmd);
    }
    // Hide content that is only a tool-call JSON blob.
    if !turn.tool_calls.is_empty() {
        let trimmed = turn.content.trim();
        if let Ok(v) = serde_json::from_str::<serde_json::Value>(trimmed) {
            let is_toolish = tool_call_from_value(&v).is_some()
                || v.get("tool_calls").is_some()
                || (v.get("name").is_some() && v.get("arguments").is_some());
            if is_toolish {
                turn.content.clear();
            }
        }
    }
}

/// One model turn with Ollama native tools (`/api/chat`), falling back to OpenAI + ```run.
pub fn chat_turn(base: &str, model: &str, messages: &[ChatMsg]) -> Result<ChatTurn> {
    match chat_turn_ollama_tools(base, model, messages) {
        Ok(mut turn) => {
            merge_content_tools(&mut turn);
            Ok(turn)
        }
        Err(_) => {
            let content = chat_messages(base, model, messages)?;
            let mut turn = ChatTurn {
                content,
                tool_calls: Vec::new(),
            };
            merge_content_tools(&mut turn);
            Ok(turn)
        }
    }
}

fn chat_turn_ollama_tools(base: &str, model: &str, messages: &[ChatMsg]) -> Result<ChatTurn> {
    let url = format!("{base}/api/chat");
    let api_messages: Vec<_> = messages.iter().map(msg_to_api_json).collect();
    let body = json!({
        "model": model,
        "messages": api_messages,
        "stream": false,
        "tools": [shell_tool_def()],
    });
    let resp = agent()
        .post(&url)
        .set("Content-Type", "application/json")
        .send_json(body)
        .with_context(|| format!("POST {url}"))?;
    let value: serde_json::Value = resp.into_json().context("decode /api/chat")?;
    if let Some(err) = value.get("error").and_then(|e| e.as_str()) {
        bail!("ollama tools: {err}");
    }
    let message = value
        .get("message")
        .ok_or_else(|| anyhow!("ollama /api/chat missing message"))?;
    let content = message
        .get("content")
        .and_then(|c| c.as_str())
        .unwrap_or("")
        .to_string();
    let tool_calls = message
        .get("tool_calls")
        .map(parse_tool_calls)
        .unwrap_or_default();
    Ok(ChatTurn {
        content,
        tool_calls,
    })
}

/// Extract shell commands from ```run fences, `RUN:` lines, or JSON tool blobs in content.
pub fn extract_run_commands(text: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut lines = text.lines().peekable();
    while let Some(line) = lines.next() {
        let trimmed = line.trim();
        if trimmed == "```run" || trimmed.starts_with("```run ") {
            let mut body = Vec::new();
            for l in lines.by_ref() {
                if l.trim().starts_with("```") {
                    break;
                }
                body.push(l);
            }
            let cmd = body.join("\n").trim().to_string();
            if !cmd.is_empty() {
                out.push(cmd);
            }
            continue;
        }
        if let Some(rest) = trimmed.strip_prefix("RUN:") {
            let cmd = rest.trim();
            if !cmd.is_empty() {
                out.push(cmd.to_string());
            }
        }
    }
    for tc in extract_json_tool_calls(text) {
        if let Some(cmd) = tc.shell_command() {
            if !out.iter().any(|c| c == &cmd) {
                out.push(cmd);
            }
        }
    }
    out
}

/// Parse tool-call JSON that models sometimes dump into `message.content`.
fn extract_json_tool_calls(text: &str) -> Vec<ToolCall> {
    let mut out = Vec::new();
    let bytes = text.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] != b'{' {
            i += 1;
            continue;
        }
        let Some(end) = find_json_object_end(text, i) else {
            i += 1;
            continue;
        };
        let slice = &text[i..=end];
        if let Ok(v) = serde_json::from_str::<serde_json::Value>(slice) {
            if let Some(tc) = tool_call_from_value(&v) {
                out.push(tc);
            } else if let Some(arr) = v.as_array() {
                for item in arr {
                    if let Some(tc) = tool_call_from_value(item) {
                        out.push(tc);
                    }
                }
            } else if let Some(calls) = v.get("tool_calls") {
                out.extend(parse_tool_calls(calls));
            }
        }
        i = end + 1;
    }
    out
}

fn find_json_object_end(text: &str, start: usize) -> Option<usize> {
    let bytes = text.as_bytes();
    if start >= bytes.len() || bytes[start] != b'{' {
        return None;
    }
    let mut depth = 0i32;
    let mut in_str = false;
    let mut escape = false;
    for (idx, &b) in bytes.iter().enumerate().skip(start) {
        if in_str {
            if escape {
                escape = false;
            } else if b == b'\\' {
                escape = true;
            } else if b == b'"' {
                in_str = false;
            }
            continue;
        }
        match b {
            b'"' => in_str = true,
            b'{' => depth += 1,
            b'}' => {
                depth -= 1;
                if depth == 0 {
                    return Some(idx);
                }
            }
            _ => {}
        }
    }
    None
}

fn tool_call_from_value(v: &serde_json::Value) -> Option<ToolCall> {
    let func = v.get("function").unwrap_or(v);
    let name = func.get("name").and_then(|n| n.as_str())?;
    let name_l = name.to_ascii_lowercase();
    if !matches!(name_l.as_str(), "run_shell" | "shell" | "run" | "execute") {
        return None;
    }
    let arguments = match func.get("arguments") {
        Some(serde_json::Value::String(s)) => {
            serde_json::from_str(s).unwrap_or_else(|_| json!({ "command": s }))
        }
        Some(a) => a.clone(),
        None => json!({}),
    };
    Some(ToolCall {
        name: name.to_string(),
        arguments,
    })
}

/// Run a shell command (user shell). Captures stdout+stderr; soft timeout via `timeout` if present.
pub fn run_shell(cmd: &str) -> String {
    use std::process::Command;
    let timeout_secs = env::var("AI_LOCAL_SHELL_TIMEOUT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(30u64);
    let output = if Command::new("timeout").arg("--version").output().is_ok() {
        Command::new("timeout")
            .arg(format!("{timeout_secs}s"))
            .arg("bash")
            .arg("-lc")
            .arg(cmd)
            .output()
    } else {
        Command::new("bash").arg("-lc").arg(cmd).output()
    };
    match output {
        Ok(o) => {
            let mut s = String::new();
            if !o.stdout.is_empty() {
                s.push_str(&String::from_utf8_lossy(&o.stdout));
            }
            if !o.stderr.is_empty() {
                if !s.is_empty() && !s.ends_with('\n') {
                    s.push('\n');
                }
                s.push_str(&String::from_utf8_lossy(&o.stderr));
            }
            if s.is_empty() {
                s = format!("(exit {})", o.status.code().unwrap_or(-1));
            } else if !o.status.success() {
                if !s.ends_with('\n') {
                    s.push('\n');
                }
                s.push_str(&format!("(exit {})", o.status.code().unwrap_or(-1)));
            }
            const MAX: usize = 32_768;
            if s.len() > MAX {
                s.truncate(MAX);
                s.push_str("\n… [truncated]");
            }
            s
        }
        Err(e) => format!("failed to spawn shell: {e}"),
    }
}

pub fn chat_messages(base: &str, model: &str, messages: &[ChatMsg]) -> Result<String> {
    let url = format!("{base}/v1/chat/completions");
    let api_messages: Vec<_> = messages.iter().map(msg_to_api_json).collect();
    let body = json!({
        "model": model,
        "messages": api_messages,
        "stream": false,
    });
    let resp = agent()
        .post(&url)
        .set("Authorization", "Bearer ollama")
        .set("Content-Type", "application/json")
        .send_json(body)
        .with_context(|| format!("POST {url}"))?;
    let chat: ChatResponse = resp.into_json().context("decode chat completions")?;
    chat.choices
        .into_iter()
        .next()
        .map(|c| c.message.content)
        .ok_or_else(|| anyhow!("empty choices from {model}"))
}

pub fn print_status(base: &str, default_model: &str) -> Result<()> {
    println!("OPENAI_API_BASE={base}/v1");
    println!("default model: {default_model}");
    let url = format!("{base}/api/tags");
    let resp = agent()
        .get(&url)
        .call()
        .with_context(|| format!("GET {url}"))?;
    let value: serde_json::Value = resp.into_json().context("decode /api/tags")?;
    println!("{}", serde_json::to_string_pretty(&value)?);
    Ok(())
}

pub fn openai_env(base: &str) -> Vec<(String, String)> {
    let api_key = env::var("OPENAI_API_KEY").unwrap_or_else(|_| "ollama".to_string());
    vec![
        ("OPENAI_API_BASE".into(), format!("{base}/v1")),
        ("OPENAI_BASE_URL".into(), format!("{base}/v1")),
        ("OPENAI_API_KEY".into(), api_key),
        ("OLLAMA_HOST".into(), base.to_string()),
    ]
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extracts_json_tool_blob() {
        let s = r#"{"name": "run_shell", "arguments": {"command":{"type":"string","value":"whoami"}}}"#;
        assert_eq!(extract_run_commands(s), vec!["whoami".to_string()]);
    }

    #[test]
    fn extracts_run_fence() {
        assert_eq!(
            extract_run_commands("```run\nuname -a\n```"),
            vec!["uname -a".to_string()]
        );
    }
}
