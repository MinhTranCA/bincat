(*
    This file is part of BinCAT.
    Copyright 2014-2017 - Airbus Group

    BinCAT is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or (at your
    option) any later version.

    BinCAT is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with BinCAT.  If not, see <http://www.gnu.org/licenses/>.
*)
(** signature of the unrolled control flow graph *)

module type T =
sig
  (** abstract data type for the abstract values in state of the CFG *)
  type domain


  (** abstract data type for the nodes of the control flow graph *)
  module State:
  sig
    
    (** data type for the decoding context *)
	type ctx_t = {
	  addr_sz: int; (** size in bits of the addresses *)
	  op_sz  : int; (** size in bits of operands *)
	}
      
    type t  = {
	  id: int; 	     		    (** unique identificator of the state *)
	  mutable ip: Data.Address.t;   (** instruction pointer *)

	  mutable v: domain; 	    (** abstract value *)
	  mutable ctx: ctx_t ; 	    (** context of decoding *)
	  mutable stmts: Asm.stmt list; (** list of statements of the succesor state *)
	  mutable final: bool;          (** true whenever a widening operator has been applied to the v field *)
	  mutable back_loop: bool; (** true whenever the state belongs to a loop that is backward analysed *)
	  mutable forward_loop: bool; (** true whenever the state belongs to a loop that is forward analysed in CFA mode *)
	  mutable branch: bool option; (** None is for unconditional predecessor. Some true if the predecessor is a If-statement for which the true branch has been taken. Some false if the false branch has been taken *)
	  mutable bytes: char list;      (** corresponding list of bytes *)
	  mutable taint_sources: Taint.t (** set of taint sources. Empty if not tainted  *)
	}

    val compare: t -> t -> int
  end


  (** oracle for retrieving any semantic information computed by the interpreter *)
  class oracle:
    domain ->
  object
    (** returns the computed concrete value of the given register 
        may raise an exception if the conretization fails 
        (not a singleton, bottom) *)
    method value_of_register: Register.t -> Z.t
      
  end
 
  (** abstract data type of the control flow graph *)
  type t

  (** [create] creates an empty CFG *)
  val create: unit -> t
    
  (** [init addr] creates a state whose ip field is _addr_ *)
  val init_state: Data.Address.t -> State.t

  (** [add_state cfg state] adds the state _state_ from the CFG _cfg_ *)
  val add_state: t -> State.t -> unit

  (** [copy_state cfg state] creates a fresh copy of the state _state_ in the CFG _cfg_.
      The fresh copy is returned *)
  val copy_state: t -> State.t -> State.t
    
  (** [remove_state cfg state] removes the state _state_ from the CFG _cfg_ *)
  val remove_state: t -> State.t -> unit

  (** [pred cfg state] returns the unique predecessor of the state _state_ in the given cfg _cfg_.
      May raise an exception if thestate has no predecessor *)
  val pred: t -> State.t -> State.t

  (** [pred cfg state] returns the successor of the state _state_ in the given cfg _cfg_. *)
  val succs: t -> State.t -> State.t list  
    
  (** iter the function on all states of the graph *)
  val iter_state: (State.t -> unit) -> t -> unit

  (** [add_successor cfg src dst] set _dst_ to be a successor of _src_ in the CFG _cfg_ *)
  val add_successor: t -> State.t -> State.t -> unit

  (** [remove_successor cfg src dst] removes _dst_ from the successor set of _src_ in the CFG _cfg_ *)
  val remove_successor: t -> State.t -> State.t -> unit
      
  (** [last_addr cfg] returns the address of latest added state of _cfg_ whose address is _addr_ *)
  val last_addr: t -> Data.Address.t -> State.t

  (** returns every state without successor in the given cfg *)
  val sinks: t -> State.t list
    
  (** [print dumpfile cfg] dump the _cfg_ into the text file _dumpfile_ *)
  val print: string -> t -> unit
    
  (** [marshal fname cfg] marshal the CFG _cfg_ and stores the result into the file _fname_ *)
  val marshal: string -> t -> unit
    
  (** [unmarshal fname] unmarshal the CFG in the file _fname_ *)
  val unmarshal: string -> t

  (** [init_abstract_value] builds the initial abstract value from the input configuration *)
  val init_abstract_value: unit -> domain * Taint.t
end

module Make: functor (D: Domain.T) ->
sig
  include T with type domain = D.t
end
