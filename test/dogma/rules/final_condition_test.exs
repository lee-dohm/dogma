defmodule Dogma.Rules.FinalConditionTest do
  use ShouldI

  alias Dogma.Rules.FinalCondition
  alias Dogma.Script
  alias Dogma.Error

  defp apply_rule(script) do
    script
    |> Script.parse("foo.ex")
    |> FinalCondition.test
  end

  defp apply_rule(script, catch_all) do
    script
    |> Script.parse("foo.ex")
    |> FinalCondition.test(catch_all: catch_all)
  end

  with "no options are passed" do
    should "not error when last condition is `true`" do
      errors = """
      cond do
        1 + 2 == 5 ->
          "Nope"
        true ->
          "Otay!"
      end
      """ |> apply_rule

      assert errors == []
    end

    should "error when last condition is not `true`" do
      errors = """
      cond do
        1 + 2 == 5 ->
          "Nope"
        _ ->
          "Otay!"
      end
      """ |> apply_rule

      assert errors == [
        %Error{
          rule: FinalCondition,
          message: "Always use true as the last condition of a cond statement",
          line: 4
        }
      ]
    end
  end

  with "catch_all option passed" do
    should "not error when last condition is catch_all" do
      errors = """
      cond do
        1 + 2 == 5 ->
          "Nope"
        :else ->
          "Otay!"
      end
      """ |> apply_rule(:else)

      assert errors == []
    end

    should "error when last condition is not catch_all" do
      errors = """
      cond do
        1 + 2 == 5 ->
          "Nope"
        _ ->
          "Otay!"
      end

      cond do
        1 + 2 == 5 ->
          "Nope"
        true ->
          "Otay!"
      end

      cond do
        1 + 2 == 5 ->
          "Nope"
        :otherwise ->
          "Otay!"
      end
      """ |> apply_rule(:else)

      assert errors == [
        %Error{
          rule: FinalCondition,
          message: "Always use :else as the last condition of a cond statement",
          line: 4
        },
        %Error{
          rule: FinalCondition,
          message: "Always use :else as the last condition of a cond statement",
          line: 11
        },
        %Error{
          rule: FinalCondition,
          message: "Always use :else as the last condition of a cond statement",
          line: 18
        }
      ]
    end

    with ":_ sent as a catch-all" do
      should "not error with _" do
        errors = """
        cond do
          1 + 2 == 5 ->
            "Nope"
          _ ->
            "Otay!"
        end
        """ |> apply_rule(:_)

        assert errors == []
      end

      should "have a helpfull error message" do
        errors = """
        cond do
          1 + 2 == 5 ->
            "Nope"
          true ->
            "Otay!"
        end
        """ |> apply_rule(:_)

        assert errors == [
          %Error{
            rule: FinalCondition,
            message: "Always use '_' as the last condition of a cond statement",
            line: 4
          }
        ]
      end
    end
  end

  with "no cachall condition" do
    should "not error on expression" do
      errors = """
      cond do
        1 + 2 == 5 ->
          "Nope"
        1 + 2 == 3 ->
          "Otay!"
      end
      """ |> apply_rule

      assert errors == []
    end

    should "not error on function call" do
      errors = """
      cond do
        1 + 2 == 5 ->
          "Nope"
        passes? ->
          "Otay!"
      end
      """ |> apply_rule

      assert errors == []
    end
  end
end
