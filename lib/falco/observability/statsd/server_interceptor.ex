defmodule Falco.Observability.Statsd.ServerInterceptor do
  @moduledoc """
  Define your interceptor and use it in endpoint
    defmodule YourService.ServerInterceptor do
      # optional
      #   * time_unit: :millisecond
      use Falco.Observability.Statsd.ServerInterceptor, statsd_module: Statix
    end
    defmodule YourService.Grpc.Endpoint do
      use GRPC.Endpoint
      intercept YourService.Grpc.ServerInterceptor
      ...
    end
  """
  defmacro __using__(opts) do
    quote location: :keep do
      @behaviour Falco.ServerInterceptor

      @statsd unquote(opts[:statsd_module])
      if !@statsd do
        raise "You have to specify :statsd_module as Falco.ServerInterceptor's option"
      end

      @time_unit unquote(opts[:time_unit] || :millisecond)
      @default_tags unquote(opts[:default_tags] || [])

      def init(opts) do
        opts
      end

      def call(
            req,
            %{
              grpc_type: grpc_type,
              __interface__: interface,
              service_name: service_name,
              method_name: method_name
            } = stream,
            next,
            opts
          ) do
        tags = [
          "grpc_service:#{service_name}",
          "grpc_method:#{method_name}",
          "grpc_type:#{grpc_type}" | @default_tags
        ]

        @statsd.increment("grpc.server.started_total", 1, tags: tags)

        req =
          if grpc_type == :client_stream || grpc_type == :bidi_stream do
            Stream.map(req, fn r ->
              @statsd.increment("grpc.server.msg_received_total", 1, tags: tags)
              r
            end)
          else
            req
          end

        send_reply = fn stream, reply, opts ->
          stream = interface[:send_reply].(stream, reply, opts)
          @statsd.increment("grpc.server.msg_sent_total", 1, tags: tags)
          stream
        end

        start = System.monotonic_time()

        try do
          result =
            next.(req, %{stream | __interface__: Map.put(interface, :send_reply, send_reply)})

          stop = System.monotonic_time()

          code =
            case result do
              {:ok, _} ->
                Falco.Status.code_name(0)

              {:ok, _, _} ->
                Falco.Status.code_name(0)

              # For compitable with older versions
              {:error, %Falco.RPCError{} = error} ->
                Falco.Status.code_name(error.status)

              {:error, _} ->
                GRPC.Status.code_name(GRPC.Status.unknown())
            end

          tags_with_code = ["grpc_code:#{code}" | tags]
          @statsd.increment("grpc.server.handled_total", 1, tags: tags_with_code)

          time = System.convert_time_unit(stop - start, :native, @time_unit)
          @statsd.histogram("grpc.server.handled_latency", time, tags: tags_with_code)

          result
        rescue
          error in Falco.RPCError ->
            code = Falco.Status.code_name(error.status)
            stop = System.monotonic_time()

            tags_with_code = ["grpc_code:#{code}" | tags]
            @statsd.increment("grpc.server.handled_total", 1, tags: tags_with_code)

            time = System.convert_time_unit(stop - start, :native, @time_unit)
            @statsd.histogram("grpc.server.handled_latency", time, tags: tags_with_code)

            reraise error, __STACKTRACE__
        catch
          kind, value ->
            reraise Exception.normalize(kind, value, __STACKTRACE__), __STACKTRACE__
        end
      end
    end
  end
end
