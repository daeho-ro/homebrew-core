class Systemd < Formula
  include Language::Python::Virtualenv

  desc "System and service manager"
  homepage "https://systemd.io"
  url "https://github.com/systemd/systemd/archive/refs/tags/v256.5.tar.gz"
  sha256 "41bb91861ab9f2f2b6cadad558ea1f8764d701452b018852146d642a850c8a8b"
  license all_of: [
    # Main license is LGPL-2.1-or-later while systemd-udevd is GPL-2.0-or-later
    "LGPL-2.1-or-later",
    "GPL-2.0-or-later",
    # The remaining licenses encompass various exceptions as defined using
    # file-specific SPDX-License-Identifier. Note that we exclude:
    # 1. "BSD-3-Clause" - it is for an unused build script (gen_autosuspend_rules.py)
    # 2. "OFL-1.1" - we do not install HTML documentation
    "CC0-1.0",
    "LGPL-2.0-or-later",
    "MIT",
    "MIT-0",
    :public_domain,
    { "LGPL-2.0-or-later" => { with: "Linux-syscall-note" } },
    { "GPL-1.0-or-later" => { with: "Linux-syscall-note" } },
    { "GPL-2.0-or-later" => { with: "Linux-syscall-note" } },
    { "GPL-2.0-only" => { with: "Linux-syscall-note" } },
    { any_of: ["BSD-3-Clause", "GPL-2.0-only" => { with: "Linux-syscall-note" }] },
    { any_of: ["MIT", "GPL-2.0-only" => { with: "Linux-syscall-note" }] },
    { any_of: ["MIT", "GPL-2.0-or-later" => { with: "Linux-syscall-note" }] },
    { any_of: ["GPL-2.0-only", "BSD-2-Clause"] },
  ]
  head "https://github.com/systemd/systemd.git", branch: "main"

  bottle do
    sha256 x86_64_linux: "ac713dbdd70cb89c7066620f49360aa9f7cc863e3b02caaed80150061cf697dc"
  end

  depends_on "coreutils" => :build
  depends_on "docbook-xsl" => :build
  depends_on "gettext" => :build
  depends_on "gperf" => :build
  depends_on "libxml2" => :build
  depends_on "libxslt" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.12" => :build
  depends_on "glib"
  depends_on "libcap"
  depends_on "libxcrypt"
  depends_on :linux
  depends_on "lz4"
  depends_on "openssl@3"
  depends_on "util-linux" # for libmount
  depends_on "xz"
  depends_on "zstd"

  resource "jinja2" do
    url "https://files.pythonhosted.org/packages/ed/55/39036716d19cab0747a5020fc7e907f362fbf48c984b14e62127f7e68e5d/jinja2-3.1.4.tar.gz"
    sha256 "4a3aee7acbbe7303aede8e9648d13b8bf88a429282aa6122a993f0ac800cb369"
  end

  resource "lxml" do
    url "https://files.pythonhosted.org/packages/e7/6b/20c3a4b24751377aaa6307eb230b66701024012c29dd374999cc92983269/lxml-5.3.0.tar.gz"
    sha256 "4e109ca30d1edec1ac60cdbe341905dc3b8f55b16855e03a54aaf59e51ec8c6f"
  end

  resource "markupsafe" do
    url "https://files.pythonhosted.org/packages/87/5b/aae44c6655f3801e81aa3eef09dbbf012431987ba564d7231722f68df02d/MarkupSafe-2.1.5.tar.gz"
    sha256 "d283d37a890ba4c1ae73ffadf8046435c76e7bc2247bbb63c00bd1a709c6544b"
  end

  def install
    venv = virtualenv_create(buildpath/"venv", "python3.12")
    venv.pip_install resources
    ENV.prepend_path "PATH", venv.root/"bin"
    ENV.append "LDFLAGS", "-Wl,-rpath,#{lib}/systemd"
    ENV["XML_CATALOG_FILES"] = etc/"xml/catalog"

    args = %W[
      --localstatedir=#{var}
      --sysconfdir=#{etc}
      -Dsysvinit-path=#{etc}/init.d
      -Dsysvrcnd-path=#{etc}/rc.d
      -Drc-local=#{etc}/rc.local
      -Dpamconfdir=#{etc}/pam.d
      -Dbashcompletiondir=#{bash_completion}
      -Dmode=release
      -Dsshconfdir=no
      -Dsshdconfdir=no
      -Dcreate-log-dirs=false
      -Dhwdb=false
      -Dtests=false
      -Dlz4=enabled
      -Dman=enabled
      -Dacl=disabled
      -Dgcrypt=disabled
      -Dgnutls=disabled
      -Dlibcurl=disabled
      -Dmicrohttpd=disabled
      -Dp11kit=disabled
      -Dpam=disabled
    ]

    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build"
    system "meson", "install", "-C", "build"
  end

  test do
    assert_match "temporary: /tmp", shell_output(bin/"systemd-path")
  end
end
