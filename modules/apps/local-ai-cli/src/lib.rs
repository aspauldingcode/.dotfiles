use anyhow::{anyhow, bail, Context, Result};
use serde::Deserialize;
use serde_json::json;
use std::env;
use std::time::Duration;

pub const DEFAULT_BASE_URL: &str = "http://127.0.0.1:11434";
pub const DEFAULT_MODEL: &str = "qwen2.5-coder:3b";

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
    message: ChatMessage,
}

#[derive(Debug, Deserialize)]
struct ChatMessage {
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
    let url = format!("{base}/v1/chat/completions");
    let body = json!({
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
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
