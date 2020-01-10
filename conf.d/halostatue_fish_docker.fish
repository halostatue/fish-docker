function _halostatue_fish_docker_uninstall -e halostatue_fish_docker_uninstall
    functions -e (functions -a | command awk '/_halostatue_fish_docker_/')
end

function _halostatue_fish_docker_print_containers --description 'Print a list of docker containers' -a select
    set -l filter -- --all
    switch $select
        case running
            set filter --filter status=running
        case stopped
            set filter --filter status=exited
    end

    docker ps --no-trunc $filter --format '{{.ID}}\n{{.Names}}' | tr ',' '\n'
end

function _halostatue_fish_docker_print_images --description 'Print a list of docker images'
    docker images --format '{{if eq .Repository "<none>"}}{{.ID}}\tUnnamed Image{{else}}{{.Repository}}:{{.Tag}}{{end}}'
end

function _halostatue_fish_docker_print_repositories --description 'Print a list of docker repositories'
    docker images --format '{{.Repository}}' | command grep -v '<none>' | command sort | command uniq
end

function _halostatue_fish_docker_print_compose_services --description 'Print a list of docker-compose services'
    docker-compose config --services 2>/dev/null | command sort
end
