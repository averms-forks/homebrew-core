class Ghc < Formula
  desc "Glorious Glasgow Haskell Compilation System"
  homepage "https://haskell.org/ghc/"
  url "https://downloads.haskell.org/~ghc/9.12.2/ghc-9.12.2-src.tar.xz"
  sha256 "0e49cd5dde43f348c5716e5de9a5d7a0f8d68d945dc41cf75dfdefe65084f933"
  license "BSD-3-Clause"
  head "https://gitlab.haskell.org/ghc/ghc.git", branch: "master"

  livecheck do
    url "https://www.haskell.org/ghc/download.html"
    regex(/href=.*?download[._-]ghc[._-][^"' >]+?\.html[^>]*?>\s*?v?(\d+(?:\.\d+)+)\s*?</i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sequoia: "c6a8718a792bb467bc76fb5a338e7c9db23255584d4fb570677f2241458bbee0"
    sha256 cellar: :any,                 arm64_sonoma:  "2dcb19546603dd64cda9ad4f1c9a38b4541164085ba4b62f004769a6b011db7f"
    sha256 cellar: :any,                 arm64_ventura: "7705ba9d0f9d329fa15d979a1fa908f068974162bbe9163e6e4b4b3c51d4567c"
    sha256 cellar: :any,                 sonoma:        "9ec5bd71034e4b11205baeec399925589a06967c2ab45d62c68b05c3aeaea945"
    sha256 cellar: :any,                 ventura:       "11c438cb71237329a613904a51677a307fbe2c7728c339480db690d1de125fe2"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "7b06492e4ea2fabe96cd970279255d4f1d35a779e3acb01f5b2b3a4acd416d42"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "python@3.13" => :build
  depends_on "sphinx-doc" => :build
  depends_on "xz" => :build
  depends_on "gmp"

  uses_from_macos "m4" => :build
  uses_from_macos "libffi"
  uses_from_macos "ncurses"

  # Build uses sed -r option, which is not available in Catalina shipped sed.
  on_catalina :or_older do
    depends_on "gnu-sed" => :build
  end

  # A binary of ghc is needed to bootstrap ghc
  resource "binary" do
    on_macos do
      on_arm do
        url "https://downloads.haskell.org/~ghc/9.10.1/ghc-9.10.1-aarch64-apple-darwin.tar.xz"
        sha256 "ffaf83b5d7a8b2c04920c6e3909c0be21dde27baf380d095fa27e840a3a2e804"
      end
      on_intel do
        url "https://downloads.haskell.org/~ghc/9.10.1/ghc-9.10.1-x86_64-apple-darwin.tar.xz"
        sha256 "8cf22188930e10d7ac5270d425e21a3dab606af73a655493639345200c650be9"
      end
    end
    on_linux do
      on_arm do
        url "https://downloads.haskell.org/~ghc/9.10.1/ghc-9.10.1-aarch64-deb10-linux.tar.xz"
        sha256 "e6df50e62b696e3a8b759670fc79207ccc26e88a79a047561ca1ccb8846157dd"
      end
      on_intel do
        url "https://downloads.haskell.org/~ghc/9.10.1/ghc-9.10.1-x86_64-ubuntu20_04-linux.tar.xz"
        sha256 "ae3be406fdb73bd2b0c22baada77a8ff2f8cde6220dd591dc24541cfe9d895eb"
      end
    end
  end

  resource "cabal-install" do
    on_macos do
      on_arm do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.14.1.1/cabal-install-3.14.1.1-aarch64-darwin.tar.xz"
        sha256 "bd40920fb3d5bcf3d78ce93445039ba43bc5edf769c52234223f25b83e3cc682"
      end
      on_intel do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.14.1.1/cabal-install-3.14.1.1-x86_64-darwin.tar.xz"
        sha256 "3690d8f7aa368141574f9eaf8e75bc26932ed7b422f5ade107d6972b3b72532f"
      end
    end
    on_linux do
      on_arm do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.14.1.1/cabal-install-3.14.1.1-aarch64-linux-deb10.tar.xz"
        sha256 "bf5fbe5d911c771b1601b80b00e9f9fb3db7f800258204322e411fdf1661a866"
      end
      on_intel do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.14.1.1/cabal-install-3.14.1.1-x86_64-linux-ubuntu20_04.tar.xz"
        sha256 "91d2b65907e95462396fa96892ebbd903861fc07b5cb74993c612e33d4c0cc65"
      end
    end
  end

  def install
    # ENV.cc and ENV.cxx return specific compiler versions on Ubuntu, e.g.
    # gcc-11 and g++-11 on Ubuntu 22.04. Using such values effectively causes
    # the bottle (binary package) to only run on systems where gcc-11 and g++-11
    # binaries are available. This breaks on many systems including Arch Linux,
    # Fedora and Ubuntu 24.04, as they provide g** but not g**-11 specifically.
    #
    # The workaround here is to hard-code both CC and CXX on Linux.
    ENV["CC"] = ENV["ac_cv_path_CC"] = OS.linux? ? "cc" : ENV.cc
    ENV["CXX"] = ENV["ac_cv_path_CXX"] = OS.linux? ? "c++" : ENV.cxx
    ENV["LD"] = ENV["MergeObjsCmd"] = "ld"
    ENV["PYTHON"] = which("python3.13")

    binary = buildpath/"binary"
    args = %W[
      --with-gmp-includes=#{Formula["gmp"].opt_include}
      --with-gmp-libraries=#{Formula["gmp"].opt_lib}
    ]
    resource("binary").stage do
      system "./configure", "--prefix=#{binary}", *args
      ENV.deparallelize { system "make", "install" }
    end

    ENV.prepend_path "PATH", binary/"bin"
    # Build uses sed -r option, which is not available in Catalina shipped sed.
    ENV.prepend_path "PATH", Formula["gnu-sed"].libexec/"gnubin" if OS.mac? && MacOS.version <= :catalina

    resource("cabal-install").stage { (binary/"bin").install "cabal" }
    system "cabal", "v2-update"
    if build.head?
      cabal_args = std_cabal_v2_args.reject { |s| s["installdir"] }
      system "cabal", "v2-install", "alex", "happy", *cabal_args, "--installdir=#{binary}/bin"
      system "./boot"
    end

    if OS.mac?
      # https://gitlab.haskell.org/ghc/ghc/-/issues/22595#note_468423
      args << "--with-ffi-libraries=#{MacOS.sdk_path_if_needed}/usr/lib"
      args << "--with-ffi-includes=#{MacOS.sdk_path_if_needed}/usr/include/ffi"
    end

    system "./configure", "--prefix=#{prefix}", "--disable-numa", "--with-system-libffi", *args
    hadrian_args = %W[
      -j#{ENV.make_jobs}
      --prefix=#{prefix}
      --flavour=release
      --docs=no-sphinx-pdfs
    ]
    # Let hadrian handle its own parallelization
    ENV.deparallelize { system "hadrian/build", "install", *hadrian_args }

    bash_completion.install "utils/completion/ghc.bash" => "ghc"
    ghc_libdir = build.head? ? lib.glob("ghc-*").first : lib/"ghc-#{version}"
    (ghc_libdir/"lib/package.conf.d/package.cache").unlink
    (ghc_libdir/"lib/package.conf.d/package.cache.lock").unlink
  end

  def post_install
    system bin/"ghc-pkg", "recache"
  end

  test do
    (testpath/"hello.hs").write('main = putStrLn "Hello Homebrew"')
    assert_match "Hello Homebrew", shell_output("#{bin}/runghc hello.hs")
  end
end
