reduce ($managed[0] | to_entries[]) as $provider
  (. ;
    if .providerInstances[$provider.key].driver == $provider.key
      and (.providerInstances[$provider.key].config | type) == "object"
    then
      .providerInstances[$provider.key].config *= $provider.value
    else
      .
    end
  )
