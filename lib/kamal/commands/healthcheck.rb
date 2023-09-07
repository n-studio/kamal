class Kamal::Commands::Healthcheck < Kamal::Commands::Base

  def run
    web = config.role(:web)

    docker :run,
      "--detach",
      "--name", container_name_with_version,
      "--publish", "#{exposed_port}:#{config.healthcheck["port"]}",
      "--label", "service=#{container_name}",
      "-e", "KAMAL_CONTAINER_NAME=\"#{container_name}\"",
      *web.env_args,
      *web.health_check_args,
      *config.volume_args,
      *web.option_args,
      config.absolute_image,
      web.cmd
  end

  def status
    pipe container_id, xargs(docker(:inspect, "--format", DOCKER_HEALTH_STATUS_FORMAT))
  end

  def container_health_log
    pipe container_id, xargs(docker(:inspect, "--format", DOCKER_HEALTH_LOG_FORMAT))
  end

  def logs
    pipe container_id, xargs(docker(:logs, "--tail", 50, "2>&1"))
  end

  def stop
    pipe container_id, xargs(docker(:stop))
  end

  def remove
    pipe container_id, xargs(docker(:container, :rm))
  end

  private
    def container_name
      [ "healthcheck", config.service, config.destination ].compact.join("-")
    end

    def container_name_with_version
      "#{container_name}-#{config.version}"
    end

    def container_id
      container_id_for(container_name: container_name_with_version)
    end

    def health_url
      "http://localhost:#{exposed_port}#{config.healthcheck["path"]}"
    end

    def exposed_port
      config.healthcheck["exposed_port"]
    end
end