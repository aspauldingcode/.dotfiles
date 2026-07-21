use anyhow::{bail, Result};
use clap::Parser;
use dendritic_local_ai::{
    base_url, chat, default_model, list_models_numbered, list_models_raw, looks_like_model_spec,
    resolve_model, tui,
};

#[derive(Debug, Parser)]
#[command(
    name = "chat",
    about = "Chat against local Ollama (interactive TUI or one-shot)",
    after_help = "Examples:\n  \
        chat\n  \
        chat -m gemma3:1b\n  \
        chat 'explain this error'\n  \
        chat -m 1 'summarize in one line'\n  \
        chat --model=qwen2.5-coder:7b -- fix this function"
)]
struct Args {
    /// Model tag or 1-based list index
    #[arg(short, long)]
    model: Option<String>,

    /// Force interactive TUI (default when no prompt is given)
    #[arg(short = 'i', long)]
    interactive: bool,

    /// List installed models (numbered)
    #[arg(short = 'l', long)]
    list: bool,

    /// Print bare model tags (for shell completion)
    #[arg(long, hide = true)]
    list_raw: bool,

    /// Prompt words (optional leading MODEL when it looks like a tag/index).
    /// Omit for the interactive TUI.
    #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
    prompt: Vec<String>,
}

fn main() -> Result<()> {
    let mut args = Args::parse();
    let base = base_url();

    if args.list_raw {
        list_models_raw(&base)?;
        return Ok(());
    }
    if args.list {
        list_models_numbered(&base)?;
        return Ok(());
    }

    let mut model_spec = args.model.clone().unwrap_or_else(default_model);

    // Legacy: `chat MODEL <prompt...>` when MODEL is tag/index.
    if args.model.is_none() && args.prompt.len() >= 2 && looks_like_model_spec(&args.prompt[0]) {
        model_spec = args.prompt.remove(0);
    }

    let model = resolve_model(&base, &model_spec)?;

    // Interactive TUI: bare `chat`, `chat -m …`, or explicit `-i`.
    if args.interactive || args.prompt.is_empty() {
        return tui::run(model);
    }

    let prompt = args.prompt.join(" ");
    if prompt.trim().is_empty() {
        bail!("empty prompt");
    }

    let reply = chat(&base, &model, &prompt)?;
    println!("{reply}");
    Ok(())
}
