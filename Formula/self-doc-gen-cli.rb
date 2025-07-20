class SelfDocGenCli < Formula
  desc "Self-documenting CLI generator with markdown templates and folder visualization"
  homepage "https://github.com/raymonepping/self_doc_gen_cli"
  url "https://github.com/raymonepping/homebrew-self-doc-gen-cli/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "a418a9efb13e09bed8ea46ac10f37c57f274417d51de2411e0d4102453f517a7"
  license "MIT"
  version "1.2.0"

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
