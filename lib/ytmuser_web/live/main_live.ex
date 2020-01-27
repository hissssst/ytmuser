defmodule YtmuserWeb.MainLive do
  use Phoenix.LiveView
  require Logger

  def render(assigns) do
    ~L"""
    <div id="player" class="player" phx-update="replace">
      <div
        class="thumbnail"
        style="background-image: url(<%= @player.thumbnail %>)"
      >
      </div>
      <div class="audiopanel">
        <div class="audioline">
          <div><label><%= @player.file %></label></div>
          <div><%= @player.status %></div>
        </div>
        <progress value="1" max="5" class="audioprogress"/></progress>
      </div>
    </div>
    <form phx-submit="submit" phx-throttle="2000">
      <input
        type="text"
        name="userinput"
        placeholder="type: ':help' to see the help message"
      >
      <label>Logged as <%= @myname %></label>
    </form>
    <div id="chat-messages" name="div" phx-update="append">
      <%= for message <- @messages do %>
        <div id="msgid<%= message.id %>">
          <p>
            <span><%= message.author %>: </span>
            <%= for line <- message.text  do %>
              <%= line %> <br>
            <% end %>
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_session, socket) do
    name = "Anon#{:rand.uniform(100_000)}"
    Logger.info("#{name} joined")

    :ok = :pg2.join(:clients, self())

    socket = assign(socket, messages: [], myname: name, player: %{
      thumbnail: "https://http.cat/404.jpg",
      file: "No file",
      status: "No status"
    })
    {:ok, socket, temporary_assigns: [messages: []]}
  end

  def handle_event("submit", %{"userinput" => value}, socket) do
    Logger.debug("wrote #{value}")
    value
    |> String.trim()
    |> Ytmuser.Room.new_message(socket)

    Logger.debug("finished #{value}")
    {:noreply, socket}
  end

  def handle_info({:message, %{text: text} = value}, socket) do
    Logger.debug("displaying #{text} message with #{value.id}")
    value = %{value | text: String.split(text, "\n")}
    {:noreply, assign(socket, messages: [value])}
  end

  def handle_info({:player, player}, socket) do
    {:noreply, assign(socket, player: player)}
  end

end
