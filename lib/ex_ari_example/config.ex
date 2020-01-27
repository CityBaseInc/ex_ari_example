defmodule ExARIExample.Config do
  @moduledoc false

  @behaviour ARI.Config
  @ingress_cidrs "INGRESS_CIDRS"
  @aor_ips "AOR_IPS"
  @public_ip "PUBLIC_IP"
  @asterisk_hostname "ASTERISK_HOSTNAME"

  @impl ARI.Config
  def aor(name) do
    aors = get_system_env(@aor_ips)

    %{
      name: name,
      fields:
        Enum.map(aors, fn ip ->
          %{
            attribute: "contact",
            value: "sip:#{ip}"
          }
        end)
    }
  end

  @impl ARI.Config
  def endpoint(name, context, transport) do
    [public_ip] = get_system_env(@public_ip)

    %{
      name: name,
      fields: [
        %{
          attribute: "identify_by",
          value: "ip"
        },
        %{
          attribute: "transport",
          value: transport
        },
        %{
          attribute: "dtmf_mode",
          value: "rfc4733"
        },
        %{
          attribute: "context",
          value: context
        },
        %{
          attribute: "disallow",
          value: "all"
        },
        %{
          attribute: "allow",
          value: "ulaw"
        },
        %{
          attribute: "direct_media",
          value: "false"
        },
        %{
          attribute: "force_rport",
          value: "true"
        },
        %{
          attribute: "rewrite_contact",
          value: "true"
        },
        %{
          attribute: "aors",
          value: name
        },
        %{
          attribute: "media_address",
          value: public_ip
        }
      ]
    }
  end

  @impl ARI.Config
  def identify(name) do
    cidrs = get_system_env(@ingress_cidrs)

    %{
      name: name,
      fields:
        [
          %{
            attribute: "endpoint",
            value: name
          }
        ] ++
          Enum.map(cidrs, fn cidr ->
            %{
              attribute: "match",
              value: cidr
            }
          end)
    }
  end

  @impl ARI.Config
  def pjsip_config do
    hostname = get_system_env(@asterisk_hostname)
    pjsip_config_path = Application.get_env(:ex_ari_example, :pjsip_config_path)

    :ex_ari_example
    |> :code.priv_dir()
    |> Path.join("templates/pjsip.conf.eex")
    |> EEx.eval_file(asterisk_hostname: hostname)
    |> write_pjsip_conf(pjsip_config_path)
  end

  defp write_pjsip_conf(data, path), do: File.write!(path, data)

  defp get_system_env(key) do
    key
    |> System.get_env()
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end
end
