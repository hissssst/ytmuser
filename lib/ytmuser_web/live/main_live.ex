defmodule YtmuserWeb.MainLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <form phx-submit="submit" phx-throttle=1000>
    <input 
      type="text"
      name="userinput"
      placeholder="type: ':help' to see the help message"
    >
    <label>Logged as <%= @myname %></label>
    </form>
    <div id="chat-messages" name="div" phx-update="prepend">
      <%= for message <- @messages do %>
        <div id="<%= message.id %>">
          <p><span><%= message.span %>: </span><%= message.text %></p>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_session, socket) do
    :ok = :pg2.join(:clients, self())
    socket = assign(socket, messages: [], myname: "Anon#{:rand.uniform(100_000)}")
    {:ok, socket, temporary_assigns: [messages: []]}
  end

  def handle_event("submit", %{"userinput" => value}, socket) do
    value
    |> String.trim()
    |> Ytmuser.Room.new_message()
    |> case do
      {:all, new_message} ->
        broadcast({:new_message, %{new_message | span: socket.assigns.myname}})
        {:noreply, socket}
      {:self, new_message} ->
        {:noreply, assign(socket, messages: [new_message])}
    end
  end

  def handle_info({:new_message, value}, socket) do
    {:noreply, assign(socket, messages: [value])}
  end

  def broadcast(msg) do
    :clients
    |> :pg2.get_local_members()
    |> Enum.each(&send(&1, msg))
  end 

end
