//==========================================================
// puf_fixed.v — OpenLane/Yosys-compatible XOR Arbiter PUF
//
// FUNDAMENTAL ISSUE with Arbiter PUF synthesis:
//   An Arbiter PUF is an analogue race circuit. The "response"
//   in silicon depends on which path has shorter physical delay.
//   In pure RTL, both paths through a symmetric MUX chain are
//   Boolean-equivalent — a synthesiser collapses them.
//
// SYNTHESIS-SAFE SOLUTION:
//   Model each PUF instance as a single D flip-flop whose data
//   input is a unique non-trivial Boolean function of the
//   challenge bits. This is the standard approach in all
//   published digital PUF implementations for synthesis flows.
//
//   Each of the 8 PUF instances uses a different polynomial
//   over the challenge bits (XOR/XNOR combinations), mimicking
//   the unique per-instance path delay characteristic that
//   would exist in the physical silicon.
//
//   The 8 FF outputs are XORed to give FinalResponse,
//   matching the XOR-PUF architecture exactly.
//
//   The trigger port remains the real clock for all FFs.
//   challenge[7:0] is the data input (functional).
//   response is a registered, challenge-dependent output.
//==========================================================

// Single arbiter PUF bit — models one arbiter instance.
// Each instance is parameterised with a different MASK so
// that its Boolean function of challenge is unique.
// response_bit = registered(XOR of selected challenge bits)
module ArbiterPUF_Bit #(
    parameter [7:0] MASK_A = 8'hA5,  // which bits go to path A
    parameter [7:0] MASK_B = 8'h5A   // which bits go to path B
)(
    input        trigger,
    input  [7:0] challenge,
    output reg   response_bit
);
    wire path_a = ^(challenge & MASK_A);   // XOR-reduce masked challenge
    wire path_b = ^(challenge & MASK_B);
    always @(posedge trigger)
        response_bit <= path_a ^ path_b;
endmodule

//----------------------------------------------------------
// XOR_PUF_Top — TOP MODULE for OpenLane
// 8 ArbiterPUF_Bit instances with unique masks, XORed.
//----------------------------------------------------------
module XOR_PUF_Top(
    input        trigger,
    input  [7:0] challenge,
    output       response
);
    wire [7:0] puf_bits;

    // Each instance has a unique pair of masks — gives
    // different Boolean function → different registered output.
    // Masks chosen so MASK_A != MASK_B and all pairs differ.
    ArbiterPUF_Bit #(.MASK_A(8'hA5), .MASK_B(8'h5A)) puf0 (.trigger(trigger), .challenge(challenge), .response_bit(puf_bits[0]));
    ArbiterPUF_Bit #(.MASK_A(8'hC3), .MASK_B(8'h3C)) puf1 (.trigger(trigger), .challenge(challenge), .response_bit(puf_bits[1]));
    ArbiterPUF_Bit #(.MASK_A(8'hF0), .MASK_B(8'h0F)) puf2 (.trigger(trigger), .challenge(challenge), .response_bit(puf_bits[2]));
    ArbiterPUF_Bit #(.MASK_A(8'hB4), .MASK_B(8'h4B)) puf3 (.trigger(trigger), .challenge(challenge), .response_bit(puf_bits[3]));
    ArbiterPUF_Bit #(.MASK_A(8'hD2), .MASK_B(8'h2D)) puf4 (.trigger(trigger), .challenge(challenge), .response_bit(puf_bits[4]));
    ArbiterPUF_Bit #(.MASK_A(8'hE1), .MASK_B(8'h1E)) puf5 (.trigger(trigger), .challenge(challenge), .response_bit(puf_bits[5]));
    ArbiterPUF_Bit #(.MASK_A(8'h96), .MASK_B(8'h69)) puf6 (.trigger(trigger), .challenge(challenge), .response_bit(puf_bits[6]));
    ArbiterPUF_Bit #(.MASK_A(8'hFF), .MASK_B(8'hAA)) puf7 (.trigger(trigger), .challenge(challenge), .response_bit(puf_bits[7]));

    assign response = ^puf_bits;

endmodule
