---
title: Introduction to Quantum Programming Languages
header-includes: |
  \usepackage{physics}
---

# OpenQASM


OpenQASM is a circuit description language developed with near-term
applications in mind, i.e., to program the (small and noisy) quantum
computers we have today. Its main goal is to serve as an intermediate
representation for higher-level compilers in order to interact with
quantum hardware.  For example, it can be used to interact with
IBM's [quantum computers](https://www.ibm.com/quantum) or Amazon's
[Braket](https://www.ibm.com/quantum), although as we shall see in future
notes, higher-level languages are also available for this task that use
OpenQASM as a compilation target.

That it is a circuit description language means that OpenQASM programs are not
meant to be run directly on a quantum computer. Instead, an OpenQASM program
is run on a classical computer to produce a quantum circuit, which can then
be handed off to a quantum computer for execution.

But why go through all of this trouble if, in the end, all we're doing
is describing quantum circuits?

There are multiple reasons why this can be beneficial:

 * **Abstraction:** In a circuit, a single line denotes a single
   qubit, and its precise location matters to the operation of the
   circuit. In OpenQASM, variables are used to represent (collections
   of) qubits, and can be given descriptive names to better relay
   their intended use, and declared in any order. The precise mapping
   of variables to qubits (known as *routing*) in a circuit is handled
   by the OpenQASM compiler. Compile-time constants can also be used
   to describe algorithms that are flexible regarding the number of
   qubits available, such as those for qubit arithmetic.
   
 * **Typing:** Variables (and subroutines, see below) must
   be declared along with their types, such as `qubit` (a qubit),
   `bit` (a classical bit), `qubit[4]` (an array of four qubits),
   `int[16]` (a classical 16-bit integer), and so on. This can not
   only be used to catch errors in programming, but can also be used
   by the OpenQASM compiler to improve the quality of the quantum
   circuit it produces.
   
 * **Structure:** Larger programs are typically written by in a
   structured fashion by combining smaller parts using things like
   conditionals, loops, and subroutines. Programming in this style
   greatly improves the ability to read, understand, and debug a
   program, even as it grows quite large. You will notice that quantum
   (or classical) circuits do not support either of these features (we
   say that they are *unstructured*), but OpenQASM does, with the
   OpenQASM compiler able to compile these down to quantum circuits.

You will likely recognise these as recurring themes in the other
languages that we will look at later.

In what follows, we give a brief overview of the core
of the language. The full documentation can be found at
[https://openqasm.com/index.html](https://openqasm.com/index.html).

### Tutorial

OpenQASM is an imperative and statically-typed language. Statements are
separated by semi-colons and whitespace is ignored.

#### Data types and variable declaration
Unsurprisingly, OpenQASM has types for declaring bits and qubits, as well as
registers of bits and registers of qubits:

    bit b;
    bit[5] b_reg;

    qubit q;
    qubit[5] q_reg;

Note that registers have a fixed size and cannot be resized after declaration.

The language also has some expected types for classical data
([booleans](https://openqasm.com/language/types.html#boolean-types),
[integers](https://openqasm.com/language/types.html#integers)) but more
interestingly for a low-level language includes data types for [floating
points](https://openqasm.com/language/types.html#floating-point-numbers), for
[angles](https://openqasm.com/language/types.html#angles) and for [complex
numbers](https://openqasm.com/language/types.html#complex-numbers), since
these are unavoidable when manipulating qubits. These can be initialised at
the same time as declaration:

    float x = 5.6;
    angle ang = pi / 3;
    complex[float] z = 3.3 + 2.2 im;

The real and imaginary parts of a complex number can be obtained as:

    float real_part = real(z);
    float imag_part = imag(z);

Most of these types have a syntax for declaring a desired size (for
integers) or precision (for floating points, angles and complex numbers)
and which we have decided to ignore for brievity's sake---in which case the
program uses a size/precisision which is specified by the target architecture.

It is important to emphasize at this point that qubits stand apart from other
data types a key way: they cannot be initialised in the same statement as
their declaration. In fact, the only built-in way to initialise a qubit is
with the special statement `reset`, which sets the qubit to the 0 computational
basis state:

    qubit q;
    reset q;

#### Unitary quantum gates
Unitary quantum operations on qubits are refered to as gates. There is only
a single built-in gate, `U`. It parametrises a single-qubit unitary as a
rotation of the Bloch sphere of the form:

$$
    U(a,b,c) = \begin{pmatrix}
      cos(a/2) & -e^{ic} sin(a/2) \\
      e^{ib} sin(a/2) & e^{i(b+c)} cos(a/2)
    \end{pmatrix}
$$


For example,

    qubit q;
    reset q;
    U(pi,0,pi) q;

enacts a Pauli X gate on the qubit `q`. Since `q` was reset to the 0 basis
state, `q` is then in the 1 basis state at the end of the program.

Since in common quantum circuits, the same gate can be applied many times,
it would be cumbersome to use this syntax for each identical call. OpenQASM
therefore provides a construct for abstracting gate names: the [`gate`
block](https://openqasm.com/language/gates.html).  For example,

    gate X a {
       U(pi, 0, pi) a;
    }

abstracts the Pauli X gate used above, while

    gate H a {
       U(pi/2, 0, pi) a;
    }

constructs a Hadamard gate.

Controlled gates can be constructed by adding a `ctrl` modifier to a
pre-existing gate:

    ctrl @ U(a,b,c) q_reg[0], q_reg[1];

Formally speaking, this implements the gate $1 \oplus U(a,b,c)$.
This can then be abstracted using the `gate` block:

    gate CX a, b {
       ctrl @ U(pi, 0, pi) a, b;
    }
    
    CX q_reg[0], q_reg[1];

constucts and runs a quantum controlled-NOT or CX gate.

For instance, here is a simple circuit for generating a Bell state:

    gate H a {
       U(pi/2, 0, pi) a;
    }

    gate CX a, b {
       ctrl @ U(pi, 0, pi) a, b;
    }
    
    qubit[2] q_reg;
    reset q_reg;

    H q_reg[0];
    CX q_reg[0], q_reg[1];

The resulting state is the Bell state
$$
    \frac{1}{\sqrt{2}} (\ket{00} + \ket{11})
$$

#### Measurements and classical control
Finally, measurements are programmed with the following syntax:

    bit b; 
    qubit q;
    reset q;

    b = measure q;

This performs a measurement of the qubit `q` in the
computational basis. The bit `b` can then be used to control
future quantum gates with standard classical control flow:
[if-else](https://openqasm.com/language/classical.html#if-else-statements)
statements, [for](https://openqasm.com/language/classical.html#for-loops)
loops, and [while](https://openqasm.com/language/classical.html#while-loops)
loops.

Finally, here is a circuit for quantum teleportation, which assembles all of
these constructs:

    gate H a {
       U(pi/2, 0, pi) a;
    }

    gate X {
       U(pi, 0, pi) a;
    }
    
    gate Z {
       U(0, 0, pi) a;
    }
    
    gate CX a, b {
       ctrl @ U(pi, 0, pi) a, b;
    }

    qubit input_state;
    reset input_state;

    // Create a Bell state
    qubit[2] bell_state;
    reset bell_state;
    H bell_state[0];
    CX bell_state[0], bell_state[1];

    // Entangle the input state with Bell state
    CX input_state, bell_state[0];

    // Measure and correct
    bit m1 = measure input_state;
    bit m2 = measure bell_state[0];
    if (m2 == true) {
        X bell_state[1];
    }
    if (m1 == true) {
       Z bell_state[1];
    }

### Deutsch-Jozsa

Let's implement the [Deutsch-Jozsa algorithm](https://en.wikipedia.org/wiki/Deutsch%E2%80%93Jozsa_algorithm) in OpenQASM. 

To keep the example small, we work on strings of two bits: $n=2$. The oracle function $f \colon \{0,1\}^2 \to \{0,1\}$ needs to be balanced or constant. Let's choose $f$ to be the XOR function. This is balanced, because as many pairs of bits have XOR 0 (namely 00 and 11) as have XOR 1 (namely 01 and 10).

To implement the oracle, we have to turn it into a unitary on 3 qubits, that takes $|x,y,z \rangle$ to $|x,y,z \mathrel\text{ XOR } f(x,y)\rangle = |x,y,Z \mathrel{\text{ XOR }} (x \mathrel{\text{ XOR }} Y)\rangle$. In other words, we need to find a 3-qubit unitary with the following truth table on computational basis states.

| $xyz$ | $x \mathrel{\text{ XOR }} y$ | $z \mathrel{\text{ XOR }} (x \mathrel{\text{ XOR }} y)$ |
|:----:|:-------:|:---------------:|
| 000 |    0    |       0         |
| 001 |    0    |       1         |
| 010 |    1    |       1         |
| 011 |    1    |       0         |
| 100 |    1    |       1         |
| 101 |    1    |       0         |
| 110 |    0    |       0         |
| 111 |    0    |       1         |

We can implement this unitary with two CNOT gates, and hence in OpenQASM as follows:

    gate Oracle x, y, z {
        ctrl @ U(pi, 0, pi) x, z;
        ctrl @ U(pi, 0, pi) y, z;
    }   
    
With the oracle in hand, we can now implement the rest of the Deutsch-Jozsa algorithm as follows:
    gate CX a, b {
       ctrl @ U(pi, 0, pi) a, b;
    }
    
    gate H a {
       U(pi/2, 0, pi) a;
    }
    
    gate X a {
       U(pi, 0, pi) a;
    }
        
    // declare three qubits
    qubit x;
    qubit y;
    qubit z;
    
    // set the three qubits to |0>, |0>, and |1>
    reset x;
    reset y;
    reset z;
    X z;
    
    // apply Hadamard to all three qubits
    H x;
    H y;
    H z;
    
    // apply the oracle
    Oracle x, y, z;
    
    // apply Hadamard to the first two qubits
    H x;
    H y;
    
    // measure the first two qubits
    bit a = measure x;
    bit b = measure y;

The output bits are $a=0$ and $b=0$, showing that $f$ was indeed balanced.

### Versions

OpenQASM is a standard that has been defined in three different versions. You
can declare which version your code is adhering to by having the following
first line in your code:

    OPENQASM 3.0;

OpenQASM 1.0 and 2.0 were mainly developed by IBM. For OpenQASM 2.0 there
are several compilers that input OpenQASM code and output a quantum circuit,
not least of which the [Qiskit](#qiskit) suite, which we will discuss next.

OpenQASM 3.0 has been defined and in beta since 2020, and is undergoing
consultation by a wider consortium of stakeholders before becoming a finalised
standard. As of the moment of writing this, support for OpenQASM 3.0 has not
been added to any of the major compilers. Temporary support is provided to
import OpenQASM 3.0 strings into Qiskit is provided by the Python package
[`qiskit-qasm3-import`](https://pypi.org/project/qiskit-qasm3-import/).


---

[Back](index.html)
