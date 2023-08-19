 function load_ssh 
  if status is-login
     and status is-interactive
     # To add a key, set -Ua SSH_KEYS_TO_AUTOLOAD keypath
     # To remove a key, set -U --erase SSH_KEYS_TO_AUTOLOAD[index_of_key]
     set -Ua SSH_KEYS_TO_AUTOLOAD ~/.ssh/id_rsa
     keychain -q -Q --eval $SSH_KEYS_TO_AUTOLOAD | source
   end
end
