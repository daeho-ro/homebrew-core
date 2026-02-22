class Redex < Formula
  desc "Bytecode optimizer for Android apps"
  homepage "https://fbredex.com/"
  license "MIT"
  head "https://github.com/facebook/redex.git", branch: "main"

  stable do
    url "https://github.com/facebook/redex/archive/refs/tags/v2025.09.18.tar.gz"
    sha256 "49be286761fb89a223a9609d58faa141e584a0c6866bf083d8408357302ee2f8"

    # Backport fix for newer Python
    patch do
      url "https://github.com/facebook/redex/commit/b9c7d5abf922eea7e38bc6031607eb30e8482f38.patch?full_index=1"
      sha256 "6e644764d2e2b3a7b8e69c8887e738fc6c6099f5f4a3bb6738eae6fd5677da6a"
    end
  end

  bottle do
    sha256 cellar: :any,                 arm64_tahoe:   "4290ded870843ef5a0f59274fe9242982c77542a1cbb367408151473849b21a1"
    sha256 cellar: :any,                 arm64_sequoia: "c894e5072ff2ebbdd21b9bcecf12d5468f6e2c1e51fe27d2d5a2ee83480b5301"
    sha256 cellar: :any,                 arm64_sonoma:  "8b739a35ed027e227bcc48ea375d6c0d7a8c7a20888a8319f828993b34a68107"
    sha256 cellar: :any,                 sonoma:        "c2eca79d391a44a6645c4d0cd17982c07316a49f20a4f3ff0b3bf5190936014b"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "576c939a85047bae7e36eb7821407eb2046eb746069b4b8e5a13635837338799"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "40a31fbf584c6f289032c1d257dc26cefb218e744ff934e0d5a99c3c48c229ff"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "boost"
  depends_on "jsoncpp"

  uses_from_macos "python"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    ENV["PYTHON"] = which("python3")

    # Avoid compiling tests which need Android SDK
    inreplace "Makefile.am" do |s|
      subdirs = s.get_make_var("SUBDIRS").split
      s.change_make_var! "SUBDIRS", subdirs.join(" ") if subdirs.delete("test")
    end

    args = %W[
      --disable-kotlin-tests
      --disable-silent-rules
      --disable-tests
      --with-boost=#{Formula["boost"].opt_prefix}
    ]

    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    resource "homebrew-test_apk" do
      url "https://raw.githubusercontent.com/facebook/redex/fa32d542d4074dbd485584413d69ea0c9c3cbc98/test/instr/redex-test.apk"
      sha256 "7851cf2a15230ea6ff076639c2273bc4ca4c3d81917d2e13c05edcc4d537cc04"
    end

    testpath.install resource("homebrew-test_apk")
    system bin/"redex", "--ignore-zipalign", "redex-test.apk", "-o", "redex-test-out.apk"
    assert_path_exists testpath/"redex-test-out.apk"
  end
end
