function asdf_cached_version -a language_tool

end

function asdf_get_version -a language_tool -d 'Retrieve language/tool version installed using asdf version manager'
  # if asdf_cached_version $language_tool; return; end
  

  set tool_version (asdf current $language_tool | cut -d ' ' -f1)
  if string match -q -i -r $tool_version "No version set for*"; return; end

  set -gx OMF_ASDF_VERSION_$language_tool $tool_version
  echo $tool_version
end

function asdf_installed -d 'Determine if asdf version manager is installed' 
  if type asdf >/dev/null 2>&1; true; else; false; end
end

function asdf_plugin_installed -a language_tool -d 'Derermine if specific language or tool is installed'
  true
end