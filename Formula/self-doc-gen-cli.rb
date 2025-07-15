class FolderTreeCli < Formula
  desc "CLI toolkit for visualizing folder structures with markdown reports"
  homepage "https://github.com/raymonepping/folder_tree_cli"
  url "https://github.com/raymonepping/homebrew-folder-tree-cli/archive/refs/tags/v1.0.5.tar.gz"
  sha256 "9a2760649996ad8df0db2e3fb7d33d0d3ad2e518859473d4a7ea853bea4b65e5"
  license "MIT"
  version "1.0.5"

  depends_on "bash"

  def install
    bin.install "bin/folder_tree" => "folder_tree"
    pkgshare.install "lib", "tpl"
    doc.install "README.md"
  end

  def caveats
    <<~EOS
      To get started, run:
        folder_tree --help

      If you want to customize or extend templates/configs,
      set this variable in your shell:
        export FOLDER_TREE_HOME=#{opt_pkgshare}

      All shared scripts and templates are available in:
        #{opt_pkgshare}/lib
        #{opt_pkgshare}/tpl
    EOS
  end

  test do
    assert_match "folder_tree", shell_output("#{bin}/folder_tree --version")
  end
end
