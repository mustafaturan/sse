# SSE

[![Build Status](https://travis-ci.org/mustafaturan/sse.svg?branch=master)](https://travis-ci.org/mustafaturan/sse)

Server Sent Events for Elixir/Plug.

Server-Sent Events (SSE) is a lightweight and standardized protocol for pushing notifications from a HTTP server to a client. In contrast to WebSocket, which offers bi-directional communication, SSE only allows for one-way communication from the server to the client. If that’s all you need, SSE has the advantages to be much simpler, to rely on HTTP 1.1 only and to offer retry semantics on broken connections by the browser.

## Table of Contents

[Installation](#installation)

[Data Structures](#data-structures)

- [Chunk](#chunk)

- [Event](#event)

[Usage](#usage)

- [Phoenix Framework](#phoenix-framework)

- [Standalone](#standalone-with-plug-withwithout-any-framework)

[Docs](#docs)

[Contributing](#contributing)

[License](#license)

## Installation

The package can be installed by adding `sse` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sse, "~> 0.4"},
    {:event_bus, ">= 1.6.0"}
  ]
end
```

**Note:** It is highly recommended to use latest version of `event_bus` library. Please make sure that `event_bus` app starts earlier than `sse` library.

## Data Structures

To send chunks of events to client you need to create a `SSE.Chunk` data structure and Event data structure to deliver events.

### Chunk

Chunk has following attributes and only the *`data`* attribute is *required*, the rest of the attributes are optional:

`comment` - The comment line can be used to prevent connections from timing out; a server can send a comment periodically to keep the connection alive. Note: SSE package keeps connection alive for you, you don't have to send comment.

`data` - The data field for the message. When the EventSource receives multiple consecutive lines that begin with data:, it will concatenate them, inserting a newline character between each one. Trailing newlines are removed.

`event` - A string identifying the type of event described. If this is specified, an event will be dispatched on the browser to the listener for the specified event name; the web site source code should use addEventListener() to listen for named events. The onmessage handler is called if no event name is specified for a message.

`id` - The event ID to set the EventSource object's last event ID value.

`retry` - The reconnection time to use when attempting to send the event. This must be an integer, specifying the reconnection time in milliseconds. If a non-integer value is specified the field is ignored.

Sample data preperation

```elixir
chunk = %SSE.Chunk{data: ["some data", "another data"]}
```

### Event

To deliver chunks, you need to notify an `%EventBus.Model.Event{}` struct to the desired topic.

An `Event` struct may have at least 3 values:

`id` - Unique event identifier (`integer | String.t`)

`data` - Chunk data (`SSE.Chunk.t`)

`topic` - Name of the topic to deliver event (`atom`)

Sample data preparation

```elixir
chunk = %SSE.Chunk{data: "some data"}
event = EventBus.Model.Event{id: UUID.uuid4(), data: chunk, topic: :a_topic_name}
```

## Usage

SSE designed to work with any Plug app. So, it can be used with/without Phoenix Framework.

### Phoenix Framework

In your `config.exs`, register events before the app start:

```elixir
config :sse,
  keep_alive: {:system, "SSE_KEEP_ALIVE_IN_MS", 1000} # Keep alive in milliseconds

config :event_bus,
  topics: [:usd_eur_pair_updated, ...] # let's say we have a usd_eur_pair_updated event

```

In your controller:

```elixir
defmodule ExchangeRateController do
  @topic :usd_eur_pair_updated

  alias SSE.Chunk

  ...

  # Sample action to display USD to EUR exchange rates
  def show(conn, _params) do
    rates = %{rates: Ticker.fetch()}
    chunk = %Chunk(data: Poison.encode!(rates))

    SSE.stream(conn, {[@topic], chunk})
  end

  ...

end
```

Let's assume you have a ticker to update exchange rates:

```elixir
defmodule Ticker do
  alias EventBus.Model.Event

  @topic :usd_eur_pair_updated

  ...

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def fetch do
    GenServer.call(__MODULE__, {:fetch})
  end

  def init(_) do
    # Let's update the rates info every second
    update_exchange_rates_later()
    {:ok, fetch_rates()}
  end

  def handle_info(:update_exchange_rates, state) do
    new_rates = fetch_rates()
    unless state == new_rates do
      rates = %{rates: new_rates}
      chunk = %Chunk{data: Poison.encode!(rates)}
      event = %Event{id: UUID.uuid4(), data: chunk, topic: @topic}
      EventBus.notify(event)
    end

    update_exchange_rates_later()
    {:noreply, new_rates}
  end

  def handle_call({:fetch}, _from, state) do
    {:reply, state, state}
  end

  defp fetch_rates do
    # Get rates from somewhere...
  end

  defp update_exchange_rates_later do
    Process.send_after(self(), :update_exchange_rates, 1000)
  end

  ...
end
```

### Standalone (with Plug, with/without any framework)

All you need to change is your controller as below, the rest is the same as the Phoenix framework sample:

```elixir
defmodule ExchangeRateController do

  @topic :usd_eur_pair_updated

  alias SSE.Chunk

  ...

  get "/exchange_rates/usd_eur" do
    rates = %{rates: Ticker.fetch()}
    chunk = %Chunk{data: Poison.encode!(rates)}

    conn
    |> Conn.put_resp_header("Access-Control-Allow-Origin", "*")
    |> SSE.stream({[@topic], chunk})
  end

  ...

end
```

## Docs

The module docs can be found at [https://hexdocs.pm/sse](https://hexdocs.pm/sse).

Reference: https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events

## Contributing

### Issues, Bugs, Documentation, Enhancements

Create an issue if there is a bug.

Fork the project.

Make your improvements and write your tests(make sure you covered all the cases).

Make a pull request.

## License

MIT

Copyright (c) 2018 Mustafa Turan

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
