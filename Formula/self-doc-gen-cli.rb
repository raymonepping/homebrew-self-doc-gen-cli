class SelfDocGenCli < Formula
  desc "Self-documenting CLI generator with markdown templates and folder visualization"
  homepage "https://github.com/raymonepping/self_doc_gen_cli"
  url "https://github.com/raymonepping/homebrew-self-doc-gen-cli/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "5db0440c759346a52563002b1e27a59b710765274dc53ff8fa8f863e987904a9"
  license "MIT"
  version "1.0.2"

  depends_on "bash"

  def install
    bin.install "bin/self_doc" => "self_doc"
    pkgshare.install "tpl" 
    doc.install "README.md"
  end

  def caveats
    <<~EOS
      To get started, run:
        self_doc --help

      To override templates/config:
        export SELF_DOC_HOME=#{opt_pkgshare}

      Template location:
        #{opt_pkgshare}/tpl
    EOS
  end

  test do
    assert_match "Usage", shell_output("#{bin}/self_doc --help")
  end
end
