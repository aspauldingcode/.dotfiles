{
  lib,
  rustPlatform,
  makeWrapper,
  defaultBaseUrl ? "http://127.0.0.1:11434",
  defaultModel ? "qwen2.5-coder:3b",
}:
rustPlatform.buildRustPackage {
  pname = "dendritic-local-ai";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/ai-chat-local \
      --set-default AI_LOCAL_BASE_URL ${lib.escapeShellArg defaultBaseUrl} \
      --set-default AI_LOCAL_DEFAULT_MODEL ${lib.escapeShellArg defaultModel} \
      --set-default OLLAMA_HOST ${lib.escapeShellArg defaultBaseUrl}
    wrapProgram $out/bin/ai-local \
      --set-default AI_LOCAL_BASE_URL ${lib.escapeShellArg defaultBaseUrl} \
      --set-default AI_LOCAL_DEFAULT_MODEL ${lib.escapeShellArg defaultModel} \
      --set-default OLLAMA_HOST ${lib.escapeShellArg defaultBaseUrl}
  '';

  meta = {
    description = "Local Ollama CLI helpers (ai-local, ai-chat-local)";
    mainProgram = "ai-chat-local";
    license = lib.licenses.mit;
  };
}
