use anyhow::{bail, Result};
use clap::Parser;
use dendritic_local_ai::{
    base_url, chat, default_model, list_models_numbered, list_models_raw, looks_like_model_spec,
    resolve_model,
};

#[derive(Debug, Parser)]
#[command(
    name = "chat",
    about = "One-shot chat against local Ollama",
    after_help = "Examples:\n  \
        chat 'explain this error'\n  \
        chat -m 1 'summarize in one line'\n  \
        chat -m gemma3:1b 'summarize in one line'\n  \
        chat --model=qwen2.5-coder:7b -- fix this function"
)]
struct Args {
    /// Model tag or 1-based list index
    #[arg(short, long)]
    model: Option<String>,

    /// List installed models (numbered)
    #[arg(short = 'l', long)]
    list: bool,

    /// Print bare model tags (for shell completion)
    #[arg(long, hide = true)]
    list_raw: bool,

    /// Prompt words (optional leading MODEL when it looks like a tag/index)
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

    if args.prompt.is_empty() {
        // clap --help already exists; bare run shows usage-ish list like the shell tool.
        eprintln!("usage: chat [options] [--] <prompt...>");
        eprintln!("       chat --list");
        eprintln!();
        eprintln!("default model: {}", default_model());
        eprintln!();
        eprintln!("available models:");
        list_models_numbered(&base)?;
        std::process::exit(1);
    }

    let model = resolve_model(&base, &model_spec)?;
    let prompt = args.prompt.join(" ");
    if prompt.trim().is_empty() {
        bail!("empty prompt");
    }

    let reply = chat(&base, &model, &prompt)?;
    println!("{reply}");
    Ok(())
}
