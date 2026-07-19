use anyhow::{Context, Result};
use clap::Parser;
use dendritic_local_ai::{base_url, default_model, list_models_numbered, openai_env, print_status};
use std::os::unix::process::CommandExt;
use std::process::Command;

#[derive(Debug, Parser)]
#[command(
    name = "ai-local",
    about = "Run a command with local Ollama OpenAI-compatible env vars",
    after_help = "Examples:\n  \
        ai-local\n  \
        ai-local --list\n  \
        ai-local aider --model openai/qwen2.5-coder:3b\n  \
        ai-local opencode"
)]
struct Args {
    /// List installed models (numbered)
    #[arg(short = 'l', long)]
    list: bool,

    /// Command and args to run with local OPENAI_* env
    #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
    command: Vec<String>,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let base = base_url();
    let default = default_model();

    if args.list {
        list_models_numbered(&base)?;
        return Ok(());
    }

    if args.command.is_empty() {
        print_status(&base, &default)?;
        return Ok(());
    }

    let prog = &args.command[0];
    let rest = &args.command[1..];
    let mut cmd = Command::new(prog);
    cmd.args(rest);
    for (k, v) in openai_env(&base) {
        cmd.env(k, v);
    }

    let err = cmd.exec();
    Err(err).with_context(|| format!("exec {prog}"))?
}
