{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  pname = "oh-my-pi";
  version = "18.6.1";

  sources = {
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-ySpoRtAphOhPB8Y2LRit03g/Uo9JT/zx4PJuWU8ydGM=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-y3gVMwuxF4d+ThM1YuqC4wAe5HDkc5NVJQe1p/BAf0o=";
    };
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-tcpc0XuMwJ7ONoRZiP1AH30QAuGrW5VgDg8yiSQkbVI=";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;

  source =
    sources.${system}
      or (throw "oh-my-pi: no prebuilt binary for system '${system}'; supported: ${lib.concatStringsSep ", " (lib.attrNames sources)}");
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${source.asset}";
    inherit (source) hash;
  };

  dontUnpack = true;
  dontStrip = true;
  dontPatchELF = true;

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/omp
    runHook postInstall
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck
    export HOME=$(mktemp -d)
    actual=$($out/bin/omp --version)
    if [ "$actual" != "omp/${version}" ]; then
      echo "version mismatch: expected 'omp/${version}', got '$actual'" >&2
      exit 1
    fi
    $out/bin/omp --smoke-test
    runHook postInstallCheck
  '';

  meta = {
    description = "AI coding agent for the terminal";
    homepage = "https://github.com/can1357/oh-my-pi";
    downloadPage = "https://github.com/can1357/oh-my-pi/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "omp";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.attrNames sources;
  };
}
