defmodule Appsignal.Phoenix.EventHandler do
  @tracer Application.get_env(:appsignal, :appsignal_tracer, Appsignal.Tracer)
  @span Application.get_env(:appsignal, :appsignal_span, Appsignal.Span)

  def attach do
    handlers = %{
      [:phoenix, :router_dispatch, :start] => &phoenix_router_dispatch_start/4,
      [:phoenix, :endpoint, :start] => &phoenix_endpoint_start/4,
      [:phoenix, :endpoint, :stop] => &phoenix_endpoint_stop/4
    }

    for {event, fun} <- handlers do
      :telemetry.attach({__MODULE__, event}, event, fun, :ok)
    end
  end

  defp phoenix_router_dispatch_start(
         _,
         _measurements,
         %{plug: controller, plug_opts: action},
         _config
       )
       when is_atom(action) do
    @span.set_name(@tracer.current_span(), "#{module_name(controller)}##{action}")
  end

  defp phoenix_router_dispatch_start(_event, _measurements, _metadata, _config) do
    :ok
  end

  def phoenix_endpoint_start(_event, _measurements, _metadata, _config) do
    "web"
    |> @tracer.create_span(@tracer.current_span())
    |> @span.set_name("call.phoenix_endpoint")
  end

  defp phoenix_endpoint_stop(_event, _measurements, _metadata, _config) do
    @tracer.close_span(@tracer.current_span())
  end

  defp module_name("Elixir." <> module), do: module
  defp module_name(module) when is_binary(module), do: module
  defp module_name(module), do: module |> to_string() |> module_name()
end