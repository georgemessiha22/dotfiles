function docker-compose --wraps='podman compose' --description 'alias docker-compose=podman compose'
  podman compose $argv
        
end
