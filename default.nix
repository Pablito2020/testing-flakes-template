{pkgs,
debug,
...
}:
{
foo = pkgs.stdenv.mkDerivation {
  pname = "foo";
  version = "0.1.0";
  src = ./.;

  buildPhase = ''
    echo ${toString debug} >> hello
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin/
  '';
};
}
