---
title: Introduction to Quantum Programming Languages
header-includes: |
  \usepackage{physics}
---

# SILQ

### Overview
SILQ is a high-level quantum programming language developed by researchers at ETH Zurich. While it bears some similarity to [Q\#](qsharp.html), it has a number of features that sets it apart, such as:

 * a sophisticated type system with, among other things, type-level distinction between classical and quantum types (using `!`), classical and quantum subroutines (using the `qfree` annotation), and quantum subroutines with and without measurement (using the `mfree` annotation);
 * automatic uncomputation of subroutines, preventing accidental measurement when variables leave scope.

SILQ programs also support using various unicode symbols, though they all have ASCII alternatives and so are not strictly necessary. In this tutorial, we will avoid their use.

SILQ programs operate much like Q\# programs in that they are allowed to mix classical and quantum computations, perform measurements at arbitrary places and branch on the result, and so forth. Unlike circuits, which are run directly on a quantum computer, we can think of SILQ programs instead as programs running on a classical computer *controlling* a quantum computer: this classical computer is able to continuously send quantum instructions, as well as the initial classical data to perform these on, to the quantum computer, and receive measurements back once the instructions have been executed. This is known as the *QRAM model* of quantum computation.

SILQ is most easily installed as a Visual Studio Code plugin, as described in the [installation instructions](https://silq.ethz.ch/install), though brave souls can also install it from [source](https://github.com/eth-sri/silq).


### Tutorial

Like most other programming languages, a SILQ program consists of a number of function definitions. A SILQ program is runnable if it contains a `main` function. The simplest possible SILQ program is something like

    def main() {
      return false;
    }

To run this program in Visual Studio Code, save it and press F5 (it should return 0).

SILQ supports a number of types and annotations to aid in programming. The simplest types are the primitive types such as `B` (Booleans), `N` (natural numbers), `Z` (integers), `int[n]` and `uint[n]` ($n$-bit signed and unsigned integers), and so on. 

Given some types `s` and `t`, we can also form complex types such as `s -> t` (functions taking inputs of type `s` and producing outputs of type `t`), `s[]` (lists of elements of type `s`), `s^n` (for some natural number `n`; $n$-ary tuples of type `s`), and `!s` (the type `s` restricted to classical values).

While most of these should be self-explanatory, the classical types `!t` require some further exposition. A value of type `!t` is a value of type `t` which is guaranteed to be classical, i.e., not in a superposition of states. Distinguishing between classical and quantum values is useful, since we can do more with classical values than quantum ones. For example, classical values can be thrown away and duplicated, but quantum ones cannot, e.g., the function

    def discard (n : !N) {
      return true;
    }

is well-typed (since it is defined only on classical natural numbers), while the function

     def discardQuantum (n : N) {
       return true;
     }

is not (as it would try to discard arbitrary quantum natural numbers, which is not possible without first measuring). The type of the built-in measurement function `measure` also reflects this distinction between classical and quantum values, in that it has type `t -> !t` (for every type `t`).

It can also be useful to distinguish between functions that measure (parts of) their input, and functions which do not. A function that does not measure any (parts of) its arguments can be annotated with the `mfree` annotation, and so will not just have type `s -> t` but in fact `s -> mfree t`. Requiring that an argument function has an `mfree`-type can be used to ensure that a superposed quantum state can be safely handed off to this function without worry that the state is destroyed by a potential measurement.

A similar annotation is the `qfree` annotation: a function of type `s -> qfree t` is not just a function from `s` to `t`, but one which neither introduces nor eliminates superpositions. In other words, a `qfree` function is a classical function which can be applied to a quantum state without worry of introducing or eliminating terms in a superposed state. This is very useful for describing *oracles* (which are the heart of algorithms such as Grover search, Deutsch-Jozsa, and many others), as these are entirely classical functions (and, indeed, these algorithms only function correctly when they are).

A final very useful type-level feature of SILQ is generic parameters. A generic parameter is a classical value known at compile-time, on which a function definition may depend. This can be useful for defining families of functions which are flexible in that they can be defined generically for one or more external parameters. For example, one would expect an algorithm for adding $n$-qubit quantum integers to work the same for any choice of $n$, and so such an algorithm should be *generic* in $n$. Generic parameters generalise the *uniform families* found in [Quipper](quipper.html). While normal arguments are given in parentheses, generic parameters are given in square brackets. For example, the function

    def bitwise_not [n:!N] (bits : B^n) qfree {
      for i in [0..n) {
        bits[i] := X(bits[i]);
      }
      return bits;
    }

takes a generic parameter `n` of type `!N` (classical natural numbers), and can be applied to a vector of Booleans of any length (since the input argument `bits` is of type `B^n`, which depends on the generic parameter `n`). Whatever the value of the `n` is, this function loops through the vector and applies the $X$ gate (or $\mathit{NOT}$ gate) to each entry. This allows us to apply this same function to vectors of different length, e.g., with the definition of `bitwise_not` above,

    def main() {
      xs := bitwise_not(false, false, true);
      ys := bitwise_not(true, true);
      return (xs,ys);
    }

is not only well-typed, it also returns `((1,1,0),(0,0))` when run as expected.

Note also that `bitwise_not` can be given the `qfree` annotation since all it ever does is apply $X$ to each qubit in the vector, and $X$ neither introduces nor eliminates superpositions. If we were to change this to apply an arbitrary function `B -> B` to each entry in the vector, e.g.,

    def bitwise_map [n:!N] (bits : B^n, f : !(B -> B)) {
      for i in [0..n) {
        bits[i] := f(bits[i]);
      }
      return bits;
    }

we would have to give up the `qfree` annotation, as we can not guarantee that `f` does not introduce or eliminate superpositions. For example,

    def main() {
      xs := bitwise_map((false, true), H);
      return xs;
    }

is well-typed (`H` is the built-in *Hadamard* gate), and running it returns the state $\frac{1}{2}(\ket{00} +
\ket{10} - \ket{01} - \ket{11})$, showing that the SILQ type system was justified in refusing to award `bitwise_map` the `qfree` annotation.

More information about SILQ (including a complete list of types, annotations, and other features) can be found in the [official documentation](https://silq.ethz.ch/documentation).

### Deutsch-Jozsa
An implementation of Deutsch-Jozsa is found below.

    def DeutschJozsa[n:!N](const f : B^n -> B^n) {
      // Initialise values.
      state := (0 : int[n]) as B^n;
      state[n] := X(state[n]);

      // Apply Hadamards.
      state := bitwise_map(state, H);

      // Apply oracle.
      state := f(state);

      // Apply Hadamards again.
      state := bitwise_map(state, H);
      state[n] := H(state[n]);

      // Measure and return result.
      return measure(state) == ((0 : int[n]) as B^n);
    }

This function returns `false` if the given function is constant and `true` if it is balanced.

---

[Back](iqps.html)
