# Pygments 2.21 escapes quotes in HTML output, so these golden-file tests no
# longer match their fixtures. sqlfluff depends on diff-cover.
_: _final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_pythonFinal: pythonPrev: {
      diff-cover = pythonPrev.diff-cover.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [
          "test_added_file_pycodestyle_html"
          "test_added_file_pyflakes_html"
          "test_added_file_pylint_html"
          "test_all_reports"
          "test_fail_under_html"
          "test_fail_under_pass_html"
        ];
      });
    })
  ];
}
