`define DEBG

`define Enable  1'b1
`define Disable 1'b0

`define ResetEnable  1'b1
`define ResetDisable 1'b0

`define MemAddrWidth 32
`define MemAddrBus   31:0
`define RegAddrWidth 5
`define RegAddrBus   4:0
`define ZeroReg      5'b0

`define DataAddrWidth 32
`define DataAddrBus 31:0
`define DataWidth 32
`define DataBus   31:0

`define RegSize   32

`define ByteWidth 8
`define ByteBus   7:0

`define InstWidth 32
`define InstBus 31:0

`define InstOpCodeInterval 6:0

`define ZeroWord 32'b0

//inst_op
`define OpcodeWidth 7
`define InstOpLUI   7'b0110111
`define InstOpAUIPC 7'b0010111
`define InstOpJAL   7'b1101111
`define InstOpJALR  7'b1100111
`define InstOpB     7'b1100011
`define InstOpLoad  7'b0000011
`define InstOpSave  7'b0100011
`define InstOpARII  7'b0010011
`define InstOpARI   7'b0110011


`define OpSelWidth 6

`define OpNOP       6'b000000

`define OpLUI       6'b010000
`define OpAUIPC     6'b010001
`define OpADD       6'b010010
`define OpXOR       6'b010011
`define OpOR        6'b010100
`define OpAND       6'b010101
`define OpSLL       6'b010110
`define OpSRL       6'b010111
`define OpSRA       6'b011000
`define OpSLT       6'b011001
`define OpSLTU      6'b011010
`define OpSUB       6'b011011

`define OpLB        6'b100000
`define OpLH        6'b100001
`define OpLW        6'b100010
`define OpLBU       6'b100011
`define OpLHU       6'b100100
`define OpSB        6'b100101
`define OpSH        6'b100110
`define OpSW        6'b100111

`define OpJAL       6'b110000
`define OpBEQ       6'b110001
`define OpBNE       6'b110010
`define OpBLT       6'b110011
`define OpBGE       6'b110100
`define OpBLTU      6'b110101
`define OpBGEU      6'b110110
`define OpJALR      6'b110111

//
`define OpTypeALU    2'b01
`define OpTypeBranch 2'b10
`define OpTypeLS     2'b11
