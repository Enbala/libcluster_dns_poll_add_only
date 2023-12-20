# LibclusterDnsPollAddOnly

This cluster staragy works the same as
[Cluster.Strategy.DNSPoll](https://github.com/bitwalker/libcluster/blob/3.3.3/lib/strategy/dns_poll.ex)
except that it will not remove the node when it is removed from the dns result.
This can be helpful when you would like the old node to do a graceful shutdown
to remove it from the cluster after its been removed from the dns results.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `libcluster_dns_poll_add_only` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:libcluster_dns_poll_add_only, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/libcluster_dns_poll_add_only>.

