defmodule Ytmuser.Message do

  defstruct [
    id:     0,
    author: "NoName",
    text:   "this is text"
  ]

  def system(text) do
    %__MODULE__{id: 0, author: "System", text: text}
  end

  def change(msg, text) do
    Enum.into([text], msg)
  end

  defimpl Collectable do

    def into(original) do
      collector_fun = fn
        message, {:cont, string} ->
          IO.inspect string
          message = %{message | text: String.trim_leading(string, "\r")}
          Ytmuser.Room.broadcast({:message, message})
          message
        message, :done -> message
        _message, :halt -> :ok
      end
      {original, collector_fun}
    end

  end
end
