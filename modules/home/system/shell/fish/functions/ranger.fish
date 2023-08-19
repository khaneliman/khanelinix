function ranger
  if [ -z "$RANGER_LEVEL" ];
    set tempfile (mktemp -t tmp.XXXXXX)
	  command ranger --choosedir=$tempfile $argv
	  set return_value $status
	  
	  if test -s $tempfile
		  set ranger_pwd (cat $tempfile)
		  if test -n $ranger_pwd -a -d $ranger_pwd
			  builtin cd -- $ranger_pwd
		  end
	  end
	
	  command rm -f -- $tempfile
	  return $return_value
  else
    exit
  end
end

