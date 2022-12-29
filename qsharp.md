---
title: Introduction to Quantum Programming Languages
header-includes: |
  \usepackage{physics}
---

# Q\#

### Overview

Q# is a domain-specific programming language (DSL), aimed at writing quantum algorithms without having to worry about implementation details such as the physical layout of a quantum computer. 

The Q# language was developed by Microsoft, and is part of their wider Quantum Development Kit, which includes:

* Q# libraries implementing several standard quantum operations and algorithms.

* Integration with classical programming languages such as Python, C#, and F#, through Microsoft's Dot.net framework.

* Ways to run your Q# programs on different targets, such as simulators, resource estimators, or actual quantum hardware using Microsoft's Azure Quantum programme. There is an orchestration language in which you can specify to run the Q# program on a simulator a number of times, and once on quantum hardware, for example.

These last two points make Q# an interesting mix between an imperative and functional programming language: Q# itself is imperative, but it can be used in a functional way. It is also not (necessarily) a circuit description language, as quantum instructions are dispatched in order, and you can use measurement results as classical data in the continuation of your program.

The easiest way to use Q# is through Microsoft's Integrated Development Environment called Visual Studio Code, following the [installation instructions](https://learn.microsoft.com/en-us/training/modules/qsharp-create-first-quantum-development-kit/2-install-quantum-development-kit-code). There is official [documentation](https://learn.microsoft.com/en-gb/training/paths/quantum-computing-fundamentals/) that is quite comprehensive. The following survey will be much briefer.

### Tutorial

Q# is an imperative language. Functions, called `operation`s, take in variables, and may return values. For example, here is an operation that creates $\ket{\pm}$ states:

    operation PlusMinus(b : Bool) : Qubit {
        use q = Qubit();
        if b { X(q); }
        H(q);
        return q;
    }

The first line says that the input is a `Bool`ean value, and the output is a `Qubit`. The second line introduces a variable `q`, that is initialised to be of type `Qubit`, standardly to the value $\ket{0}$. If the input Boolean was true, an `X` gate is applied to turn `q` into $\ket{1}$. Then, `H` applies a Hadamard gate, and finally, the qubit is returned.

Apart from Hadamard, you can have controlled-not gates, with `CNOT`, which takes two `Qubit`s. In fact, `CNOT` will accept a list of qubits to target, and a qubit to control them with, like so:

    operation Oracle(cs : Qubit[], t : Qubit) : Unit is Adj {
        for c in cs {
            CNOT(c, t);
        }
    }    

Here, `Unit` is a type that says that this operation does not return a value (like `void` in C). The annotation `is Adj` indicates that this operation implements a unitary transformation and has an adjoint specialisation. (There is also an annotation `is Ctl` indicating that the operation has a controlled specialisation, and `is Adj+Ctl` to say it has both.)

Here is an operation that implements $\alpha\ket{0}+\beta\ket{1} \mapsto \alpha \ket{00} + \beta\ket{11}$:


    operation Share(a : Qubit) : (Qubit, Qubit) {
        use b = Qubit();
        CNOT(b,a);
        return (a,b);
    }

To measure, there is an operation `M` that takes a `Qubit` and has output type `Result`. A variable of type `Result` can only have two values: `Zero` and `One`. 

    operation GenerateRandomBit() : Result {
        use q = Qubit();
        H(q);
        return M(q);
    }

Measurement using `M` automatically discard the qubit. When you no longer need an unmeasured `Qubit`, you need to `Reset` it. The compiler will complain if you have not discarded all qubits in use by the end of the program. 

There are other types than `Qubit` and `Result`, such as `Bool`, `Int`, `Double`, and `String`, and you can build custom data types on those basic ones such as arrays. 

### Deutsch-Jozsa

To execute a Q# program takes some syntax. Here is a full implementation of the Deutsch-Jozsa algorithm, using the operation `Oracle` above:

    namespace DeutschJozsa {

        open Microsoft.Quantum.Canon;
        open Microsoft.Quantum.Intrinsic;
        open Microsoft.Quantum.Measurement;

        operation DeutschJozsa(n:Int, oracle:((Qubit[], Qubit)=>Unit)) : Boolean {
          mutable isFunctionConstant = true;
          use (qn, q2) = (Qubit[n], Qubit());
          X(q2);
          ApplyToEachA(H, qn);
          H(q2);
          oracle(qn, q2);                       
          ApplyToEachA(H, qn);
          if (MeasureAllZ(qn) != Zero) {
            set isFunctionConstant = false;
          }
          ResetAll(qn);       
          Reset(q2);       
          return isFunctionConstant;
        }

        @EntryPoint()
        operation Main() : Bool {
          Message($"The operation Oracle is ");
          mutable b = DeutschJozsa(1,Oracle);
          if (b) {
            Message($"balanced.");
          } else {
          Message($"constant.");
        }
        return b;
      }

As you can see, a very nice feature of the Q# framework is that you can continue to compute using the result of a measurement as if nothing happened. This happens in `Main` above, where a `Result` type is coerced into `Bool` so the conditional `if` can act on it.

# Advanced features

There are several advanced libraries and features to explore. For example:

    open Microsoft.Quantum.Diagnostics;

provides an operation called `DumpMachine`, which will output the (simulated) current state of the computation. For example, if a qubit is initialised in state $\ket{0}$, `DumpMachine` will say so:

    |0⟩:     1.000000 +  0.000000 i  ==     ******************** [ 1.000000 ]   
    |1⟩:     0.000000 +  0.000000 i  ==                          [ 0.000000 ]

[Back](iqps.html)
