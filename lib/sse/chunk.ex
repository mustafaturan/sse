defmodule SSE.Chunk do
  @moduledoc """
  Structure and type for Chunk model
  """

  @enforce_keys [:data]

  defstruct [:comment, :event, :data, :id, :retry]

  @typedoc """
  Defines the Chunk struct.
  Reference: https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Fields

  * :comment - The comment line can be used to prevent connections from timing
  out; a server can send a comment periodically to keep the connection alive.
  SSE package keeps connection alive, so you don't have to send the comment.
  * :data - The data field for the message. When the EventSource receives
  multiple consecutive lines that begin with data:, it will concatenate them,
  inserting a newline character between each one. Trailing newlines are
  removed.
  * :event - A string identifying the type of event described. If this is
  specified, an event will be dispatched on the browser to the listener for
  the specified event name; the web site source code should use
  addEventListener() to listen for named events. The onmessage handler is
  called if no event name is specified for a message.
  * :id - The event ID to set the EventSource object's last event ID value.
  * :retry - The reconnection time to use when attempting to send the event.
  This must be an integer, specifying the reconnection time in milliseconds.
  If a non-integer value is specified the field is ignored.
  """
  @type t :: %__MODULE__{
          comment: String.t() | nil,
          data: list(String.t()),
          event: String.t() | nil,
          id: String.t() | nil,
          retry: integer() | nil
        }

  @spec build(t()) :: String.t()
  def build(%__MODULE__{
        comment: comment,
        data: data,
        event: event,
        id: id,
        retry: retry
      }) do
    build_field("", comment) <> build_field("id", id) <>
      build_field("event", event) <> build_data(data) <>
      build_field("retry", retry) <> "\n"
  end

  @spec build_data(nil) :: no_return()
  defp build_data(nil) do
    raise("Chunk data can't be blank!")
  end

  @spec build_data(list(String.t())) :: String.t()
  defp build_data(data_list) when is_list(data_list) do
    Enum.reduce(data_list, "", fn(data, acc) ->
      acc <> "data: #{data}\n"
    end)
  end

  @spec build_data(String.t()) :: String.t()
  defp build_data(data) do
    "data: #{data}\n"
  end

  @spec build_field(String.t(), nil) :: String.t()
  defp build_field(_, nil) do
    ""
  end

  @spec build_field(String.t(), String.t() | integer()) :: String.t()
  defp build_field(field, value) do
    "#{field}: #{value}\n"
  end
end
