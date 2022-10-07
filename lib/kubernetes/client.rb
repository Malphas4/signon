require "kubeclient"

module Kubernetes
  class Client
    API_VERSION = "v1".freeze
    API_SERVER = "https://kubernetes.default.svc".freeze
    SERVICE_ACCOUNT = "/var/run/secrets/kubernetes.io/serviceaccount".freeze

    BEARER_TOKEN_FILE = "#{SERVICE_ACCOUNT}/token".freeze
    CA_FILE = "#{SERVICE_ACCOUNT}/ca.crt".freeze
    NAMESPACE_FILE = "#{SERVICE_ACCOUNT}/namespace".freeze

    def initialize
      ssl_options = {}
      ssl_options[:ca_file] = CA_FILE if File.exist?(CA_FILE)

      @client = Kubeclient::Client.new(
        API_SERVER, API_VERSION,
        auth_options: { bearer_token_file: BEARER_TOKEN_FILE },
        ssl_options:
      )
    end

    def namespace
      @namespace ||= File.read(NAMESPACE_FILE)
    end

    def get_config_map(name)
      @client.get_config_map(name, namespace)
    end

    def apply_secret(name, data)
      resource = Kubeclient::Resource.new({
        apiVersion: API_VERSION,
        kind: "Secret",
        metadata: {
          name:,
          namespace:,
        },
        type: "Opaque",
        data: data.transform_values { |v| Base64.encode64(v.to_s) },
      })

      @client.apply_secret(resource, field_manager: "signon")
    end
  end
end
