defmodule YtmuserWeb.MainLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <form phx-change="change">
      <progress value="<%= @value %>" max="100">xxx</progress>
    </form>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, value: 0)}
  end

  def handle_event("change", _, socket) do
    IO.puts "..."
    {:noreply, socket}
  end

end
