defmodule Cluster.Strategy.DNSPollAddOnlyTest do
  @moduledoc false

  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  defmodule Nodes do
    @moduledoc false

    def connect(caller, result \\ true, node) do
      send(caller, {:connect, node})
      result
    end

    def disconnect(caller, result \\ true, node) do
      send(caller, {:disconnect, node})
      result
    end

    def list_nodes(nodes) do
      nodes
    end
  end

  alias Cluster.Strategy.DNSPollAddOnly, as: DNSPoll

  describe "start_link/1" do
    test "adds new nodes" do
      capture_log(fn ->
        [
          %Cluster.Strategy.State{
            topology: :dns_poll,
            config: [
              polling_interval: 100,
              query: "app",
              node_basename: "node",
              resolver: fn _query ->
                [
                  {10, 0, 0, 1},
                  {10, 0, 0, 2},
                  {10_761, 33_408, 1, 41_584, 47_349, 47_607, 34_961, 243}
                ]
              end
            ],
            connect: {Nodes, :connect, [self()]},
            disconnect: {Nodes, :disconnect, [self()]},
            list_nodes: {Nodes, :list_nodes, [[]]}
          }
        ]
        |> DNSPoll.start_link()

        assert_receive {:connect, :"node@10.0.0.1"}, 100
        assert_receive {:connect, :"node@10.0.0.2"}, 100
        assert_receive {:connect, :"node@2a09:8280:1:a270:b8f5:b9f7:8891:f3"}, 100
      end)
    end
  end

  test "does not remove nodes" do
    capture_log(fn ->
      [
        %Cluster.Strategy.State{
          topology: :dns_poll,
          config: [
            polling_interval: 100,
            query: "app",
            node_basename: "node",
            resolver: fn _query -> [{10, 0, 0, 1}] end
          ],
          connect: {Nodes, :connect, [self()]},
          disconnect: {Nodes, :disconnect, [self()]},
          list_nodes: {Nodes, :list_nodes, [[:"node@10.0.0.1", :"node@10.0.0.2"]]},
          meta: MapSet.new([:"node@10.0.0.1", :"node@10.0.0.2"])
        }
      ]
      |> DNSPoll.start_link()

      refute_receive {:disconnect, :"node@10.0.0.2"}, 100
    end)
  end

  test "keeps state" do
    capture_log(fn ->
      [
        %Cluster.Strategy.State{
          topology: :dns_poll,
          config: [
            polling_interval: 100,
            query: "app",
            node_basename: "node",
            resolver: fn _query -> [{10, 0, 0, 1}] end
          ],
          connect: {Nodes, :connect, [self()]},
          disconnect: {Nodes, :disconnect, [self()]},
          list_nodes: {Nodes, :list_nodes, [[:"node@10.0.0.1"]]},
          meta: MapSet.new([:"node@10.0.0.1"])
        }
      ]
      |> DNSPoll.start_link()

      refute_receive {:disconnect, _}, 100
      refute_receive {:connect, _}, 100
    end)
  end

  test "does not connect to anything with missing config params" do
    capture_log(fn ->
      [
        %Cluster.Strategy.State{
          topology: :dns_poll,
          config: [
            polling_interval: 100,
            resolver: fn _query -> [{10, 0, 0, 1}] end
          ],
          connect: {Nodes, :connect, [self()]},
          disconnect: {Nodes, :disconnect, [self()]},
          list_nodes: {Nodes, :list_nodes, [[]]}
        }
      ]
      |> DNSPoll.start_link()

      refute_receive {:disconnect, _}, 100
      refute_receive {:connect, _}, 100
    end)
  end

  test "does not connect to anything with invalid config params" do
    capture_log(fn ->
      [
        %Cluster.Strategy.State{
          topology: :dns_poll,
          config: [
            query: :app,
            node_basename: "",
            polling_interval: 100,
            resolver: fn _query -> [{10, 0, 0, 1}] end
          ],
          connect: {Nodes, :connect, [self()]},
          disconnect: {Nodes, :disconnect, [self()]},
          list_nodes: {Nodes, :list_nodes, [[]]}
        }
      ]
      |> DNSPoll.start_link()

      refute_receive {:disconnect, _}, 100
      refute_receive {:connect, _}, 100
    end)
  end

  test "looks up both A and AAAA records" do
    result = DNSPoll.lookup_all_ips("example.org" |> String.to_charlist())
    sizes = result |> Enum.map(fn ip -> tuple_size(ip) end) |> Enum.uniq() |> Enum.sort()
    assert(sizes == [4, 8])
  end
end
