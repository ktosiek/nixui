{ stdenv, fetchurl, buildEnv, makeWrapper
, xlibs, alsaLib, dbus, glib, gtk, atk, pango, freetype, fontconfig
, gdk_pixbuf, cairo, zlib, nss, nssTools, nspr, gconf, expat, udev, libcap
, libnotify}:
let
  bits = if stdenv.system == "x86_64-linux" then "x64"
         else "ia32";

  useGCC = stdenv ? gcc;

  nwEnv = buildEnv {
    name = "node-webkit-env";
    paths = [
      xlibs.libX11 xlibs.libXrender glib gtk atk pango cairo gdk_pixbuf
      freetype fontconfig xlibs.libXcomposite alsaLib xlibs.libXdamage
      xlibs.libXext xlibs.libXfixes nss nspr gconf expat dbus xlibs.libXtst
      xlibs.libXi xlibs.libXcursor xlibs.libXrandr libcap libnotify
      (if useGCC then stdenv.gcc else stdenv.cc)
    ];
  };

in stdenv.mkDerivation rec {
  name = "node-webkit-${version}";
  version = "0.11.2";

  src = fetchurl {
    url = "http://dl.node-webkit.org/v${version}/node-webkit-v${version}-linux-${bits}.tar.gz";
    sha256 = if bits == "x64" then
      "1iby0yrnbk9xfcsfz59f6g00l6rxiyxvq78shs0c145ky7lknq5q" else
      "1hk3c9z3kwmqaj87vc5k1a7fv8jhkyqw1wjmsl3q5i50w880h398";
  };

  installPhase = ''
    mkdir -p $out/share/node-webkit
    cp -R * $out/share/node-webkit

    patchelf --set-interpreter "$(cat $NIX_${if useGCC then "GCC" else "CC"}/nix-support/dynamic-linker)" $out/share/node-webkit/nw
    patchelf --set-interpreter "$(cat $NIX_${if useGCC then "GCC" else "CC"}/nix-support/dynamic-linker)" $out/share/node-webkit/nwsnapshot

    ln -s ${udev}/lib/libudev.so $out/share/node-webkit/libudev.so.0

    patchelf --set-rpath "${nwEnv}/lib:${nwEnv}/lib64:$out/share/node-webkit" $out/share/node-webkit/nw
    patchelf --set-rpath "${nwEnv}/lib:${nwEnv}/lib64:$out/share/node-webkit" $out/share/node-webkit/nwsnapshot

    mkdir -p $out/bin
    ln -s $out/share/node-webkit/nw $out/bin
    ln -s $out/share/node-webkit/nwsnapshot $out/bin
  '';

  buildInputs = [ makeWrapper ];

  meta = with stdenv.lib; {
    description = "An app runtime based on Chromium and node.js";
    homepage = https://github.com/rogerwang/node-webkit;
    platforms = ["i686-linux" "x86_64-linux"];
    maintainers = [ maintainers.offline ];
    license = licenses.bsd3;
  };
}
