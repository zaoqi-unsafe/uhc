%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Coercion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(9 codegen) hs module {%{EH}Core.Coercion} import({%{EH}Base.Common},{%{EH}Opts.Base})
%%]

%%[(9 codegen) hs import({%{EH}Ty},{%{EH}Core})
%%]

%%[(9 codegen) hs import({%{EH}AbstractCore})
%%]

%%[(9 codegen) hs import(qualified Data.Map as Map,qualified Data.Set as Set)
%%]

%%[doesWhat doclatex
A Coercion represents incomplete code, in that it contains a hole to be filled in later.
Conceptually, the coercion type is defined only by:

\begin{pre}
type Coe = CExpr -> CExpr
\end{pre}

In the implementation here, the hole is represented by CExpr_CoeArg.

We also need to manipulate coercions so more structure is encoded in @Coe@ to match on coercion variants.
In the end, a coercion is applied to a CExpr to yield code,
see coeEvalOn in Core/Subst.
Additionally, this can be done in a lazy manner yielding a substitution CSubst
to be applied at the last possible moment.
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Coercion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

The semantics of a coercion is its application to a CExpr. See coeEvalOn.

%%[(9 codegen) hs export(Coe, Coe'(..))
type Coe = Coe' CExpr CBind CBound CTy
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Coercion for lamda
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

A LRCoe represents a coercion in a much more finegrained manner:
- a right Coe list, a list of coercions for building the rhs side of a subsumption, which must be the lambda
- a left Coe list a list of coercions for building the lhs side of a subsumption, which must be an application or other expr using the args of the left Coe

%%[(9 codegen) hs export(LRCoeKind(..),lrcoeKindOfCoe)
data LRCoeKind = LRCoeId | LRCoeOther deriving Eq

lrcoeKindAnd :: LRCoeKind -> LRCoeKind -> LRCoeKind
lrcoeKindAnd LRCoeId LRCoeId = LRCoeId
lrcoeKindAnd _       _       = LRCoeOther

lrcoeKindOfCoe :: Coe -> LRCoeKind
lrcoeKindOfCoe c = if acoreCoeIsId c then LRCoeId else LRCoeOther
%%]

%%[(9 codegen) hs export(LRCoe(..),emptyLRCoe)
data LRCoe
  = LRCoe
      { lrcoeKind		:: LRCoeKind
      , lrcoeLeftL		:: [Coe]
      , lrcoeRightL 	:: [Coe]
      }

emptyLRCoe :: LRCoe
emptyLRCoe = LRCoe LRCoeId [] []
%%]

%%[(9 codegen) hs export(lrcoeIsId)
lrcoeIsId :: LRCoe -> Bool
lrcoeIsId c = lrcoeKind c == LRCoeId
%%]

%%[(9 codegen) hs export(mkLRCoe)
mkLRCoe :: Coe -> Coe -> LRCoe
mkLRCoe l r = LRCoe LRCoeOther [l] [r]

mkIdLRCoe' :: Coe -> Coe -> LRCoe
mkIdLRCoe' l r = LRCoe LRCoeId [l] [r]
%%]

%%[(9 codegen) hs export(mkIdLRCoeWith)
mkIdLRCoeWith :: HsName -> () -> LRCoe
mkIdLRCoeWith n m = mkIdLRCoe' (acoreCoeAppN [(acoreVar n)]) (acoreCoeLam1 n)
%%]

%%[(9 codegen) hs export(lrcoeLSingleton,lrcoeRSingleton,lrcoeLFromList,lrcoeRFromList)
lrcoeLFromList :: [Coe] -> LRCoe
lrcoeLFromList c = LRCoe LRCoeOther c []

lrcoeRFromList :: [Coe] -> LRCoe
lrcoeRFromList c = LRCoe LRCoeOther [] c

lrcoeLSingleton :: Coe -> LRCoe
lrcoeLSingleton c = LRCoe (lrcoeKindOfCoe c) [c] []

lrcoeRSingleton :: Coe -> LRCoe
lrcoeRSingleton c = LRCoe (lrcoeKindOfCoe c) [] [c]
%%]

%%[(9 codegen) hs export(lrcoeUnion)
lrcoeUnion :: LRCoe -> LRCoe -> LRCoe
lrcoeUnion (LRCoe k1 l1 r1) (LRCoe k2 l2 r2) = LRCoe (lrcoeKindAnd k1 k2) (l1 ++ l2) (r1 ++ r2)
%%]

