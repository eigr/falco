opts = [interceptors: [Falco.Logger.Client]]
opts =
  if System.get_env("TLS") do
    ca_path = Path.expand("./tls/ca.pem", :code.priv_dir(:route_guide))
    cred = Falco.Credential.new(ssl: [cacertfile: ca_path])
    [{:cred, cred}|opts]
  else
    opts
  end

{:ok, channel} = Falco.Stub.connect("localhost:10000", opts)
RouteGuide.Client.main(channel)
