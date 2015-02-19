%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EHC Compile Phase building blocks: parsers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CompilePhase building blocks: parsers

%%[8 module {%{EH}EHC.CompilePhase.Parsers}
%%]

%%[8 import(UU.Parsing, UU.Parsing.Offside)
%%]
%%[8 import(qualified UHC.Util.ScanUtils as ScanUtils, {%{EH}Scanner.Common})
%%]
%%[8 import(UHC.Util.ParseUtils)
%%]
%%[99 import(Control.Exception as CE)
%%]

%%[8 import(Control.Monad.State)
%%]

%%[8 import({%{EH}EHC.Common})
%%]
%%[8 import({%{EH}EHC.CompileUnit})
%%]
%%[8 import({%{EH}EHC.CompileRun})
%%]
-- EH parser
%%[8 import(qualified {%{EH}EH} as EH, qualified {%{EH}EH.Parser} as EHPrs)
%%]
-- HS parser
%%[8 import(qualified {%{EH}HS} as HS, qualified {%{EH}HS.Parser} as HSPrs)
%%]
-- HI parser
%%[50 import(qualified {%{EH}HI} as HI)
%%]
-- Core parser
%%[(8 corein) import(qualified {%{EH}Core} as Core, qualified {%{EH}Core.Parser} as CorePrs)
%%]
-- CoreRun parser
%%[(8 corerun) import( qualified {%{EH}CoreRun} as CoreRun)
%%]
-- TyCore parser
%%[(50 codegen tycore) import(qualified {%{EH}TyCore} as C)
%%]
-- Grin parser
%%[(8 codegen grinparser) import(qualified {%{EH}GrinCode} as Grin, qualified {%{EH}GrinCode.Parser} as GrinParser)
%%]

-- serialization
%%[50 import(qualified UHC.Util.Binary as Bin, UHC.Util.Serialize)
%%]
-- config
%%[50 import(qualified {%{EH}Config} as Cfg)
%%]
%%[50 import(qualified {%{EH}SourceCodeSig} as Sig)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: parsing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
-- | Generalization of parser invocation
cpParseWithFPath
  :: (EHCCompileRunner m, PP msg)
     => (ScanUtils.ScanOpts -> FilePath -> Handle -> IO inp)			-- tokenize/scan file
     -> (parser -> inp -> (a,[msg]))									-- parse tokens
     -> ([Err] -> EHCompilePhaseT m out)									-- monadic output from errors
     -> parser															-- the parser
     -> ScanUtils.ScanOpts												-- options to the tokenizer/scanner
     -> EcuUpdater a													-- updater of state
     -> Maybe FPath														-- possibly overriding FilePath instead of default derived from state for this module name
     -> HsName															-- module name
     -> EHCompilePhaseT m out
cpParseWithFPath
      scan parse seterrs
      parser scanOpts store mbFp modNm
 = do { cr <- get
      ; (fn,fh) <- liftIO $ openFPath (maybe (ecuFilePath (crCU modNm cr)) id mbFp) ReadMode False
      ; tokens  <- liftIO $ scan scanOpts fn fh
      ; let (res,msgs) = parse parser tokens
            errs       = map (rngLift emptyRange mkPPErr) msgs
      ; cpUpdCU modNm (store res)
      ; seterrs errs
      }

-- cpParseOffsideWithFPath :: HSPrs.HSParser a -> ScanUtils.ScanOpts -> EcuUpdater a -> String -> Maybe FPath -> HsName -> EHCompilePhase ()
-- `HSPrs.HSParser a' is a type synonym for `OffsideParser [Token] Pair Token (Maybe Token) a' but is not expanded as such...
cpParseOffsideWithFPath :: EHCCompileRunner m => OffsideParser [Token] Pair Token (Maybe Token) a -> ScanUtils.ScanOpts -> EcuUpdater a -> String -> Maybe FPath -> HsName -> EHCompilePhaseT m ()
cpParseOffsideWithFPath parser scanOpts store description mbFp modNm
  = cpParseWithFPath offsideScanHandle parseOffsideToResMsgs (cpSetLimitErrsWhen 5 description) parser scanOpts store mbFp modNm
{-
 = do { cr <- get
      ; (fn,fh) <- liftIO $ openFPath (maybe (ecuFilePath (crCU modNm cr)) id mbFp) ReadMode False
      ; tokens  <- liftIO $ offsideScanHandle scanOpts fn fh
      -- ; liftIO $ putStrLn $ show tokens -- does not work, no Show instance
      ; let (res,msgs) = parseOffsideToResMsgs parser tokens
            errs       = map (rngLift emptyRange mkPPErr) msgs
      ; cpUpdCU modNm (store res)
      ; cpSetLimitErrsWhen 5 description errs
      }
-}
%%]
      
%%[8 export(cpParseOffside)
cpParseOffside :: EHCCompileRunner m => HSPrs.HSParser a -> ScanUtils.ScanOpts -> EcuUpdater a -> String -> HsName -> EHCompilePhaseT m ()
cpParseOffside parser scanOpts store description modNm
 = cpParseOffsideWithFPath parser scanOpts store description Nothing modNm
%%]

%%[8888 export(cpParsePlain)
cpParsePlainWithHandleToErrs :: EHCCompileRunner m => PlainParser Token a -> ScanUtils.ScanOpts -> EcuUpdater a -> (String, Handle) -> HsName -> EHCompilePhaseT m [Err]
cpParsePlainWithHandleToErrs parser scanOpts store (fn,fh) modNm
 = do { cr <- get
      ; tokens  <- liftIO $ scanHandle scanOpts fn fh
      ; let (res,msgs) = parseToResMsgs parser tokens
            errs       = map (rngLift emptyRange mkPPErr) msgs
      ; when (null errs)
             (cpUpdCU modNm (store res))
      ; return errs
      }

cpParsePlainToErrs :: EHCCompileRunner m => PlainParser Token a -> ScanUtils.ScanOpts -> EcuUpdater a -> FPath -> HsName -> EHCompilePhaseT m [Err]
cpParsePlainToErrs parser scanOpts store fp modNm
 = do { fnfh@(fn,fh) <- liftIO $ openFPath fp ReadMode False
      ; cpParsePlainWithHandleToErrs parser scanOpts store fnfh modNm
      }

cpParsePlain :: EHCCompileRunner m => PlainParser Token a -> ScanUtils.ScanOpts -> EcuUpdater a -> String -> FPath -> HsName -> EHCompilePhaseT m ()
cpParsePlain parser scanOpts store description fp modNm
 = do { errs <- cpParsePlainToErrs parser scanOpts store fp modNm
      ; cpSetLimitErrsWhen 5 description errs
      }
%%]

%%[8 export(cpParseEH)
cpParseEH :: EHCCompileRunner m => HsName -> EHCompilePhaseT m ()
cpParseEH
  = cpParseOffside EHPrs.pAGItf (ehScanOpts defaultEHCOpts) ecuStoreEH "Parse (EH syntax) of module"
%%]

%%[(8 grinparser) export(cpParseGrin)
cpParseGrin :: EHCCompileRunner m => HsName -> EHCompilePhaseT m ()
cpParseGrin modNm
  = do { cr <- get
       ; let  (ecu,_,opts,fp) = crBaseInfo modNm cr
              fpC     = fpathSetSuff "grin" fp
       ; cpMsg' modNm VerboseALot "Parsing" Nothing fpC
       ; cpParsePlain GrinParser.pModule grinScanOpts ecuStoreGrin "Parse grin" fpC modNm
       ; return ()
       }
%%]

%%[8.cpParseHs export(cpParseHs)
cpParseHs :: EHCCompileRunner m => HsName -> EHCompilePhaseT m ()
cpParseHs modNm
  = do { cr <- get
       ; let (_,opts) = crBaseInfo' cr
       ; cpParseOffside (HSPrs.pAGItf opts) (hsScanOpts opts) ecuStoreHS "Parse (Haskell syntax) of module" modNm
       }
%%]

%%[99 -8.cpParseHs export(cpParseHs)
cpParseHs :: EHCCompileRunner m => Bool -> HsName -> EHCompilePhaseT m ()
cpParseHs litmode modNm
  = do { cr <- get
       ; let  (ecu,_,opts,_) = crBaseInfo modNm cr
       ; cpParseOffsideWithFPath
           (HSPrs.pAGItf opts) ((hsScanOpts opts) {ScanUtils.scoLitmode = litmode}) ecuStoreHS
           ("Parse (" ++ (if litmode then "Literate " else "") ++ "Haskell syntax) of module")
           Nothing modNm
       }
%%]

%%[50 export(cpParseOffsideStopAtErr)
cpParseOffsideStopAtErr :: EHCCompileRunner m => HSPrs.HSParser a -> ScanUtils.ScanOpts -> EcuUpdater a -> HsName -> EHCompilePhaseT m ()
cpParseOffsideStopAtErr parser scanOpts store modNm
 = do { cr <- get
      ; (fn,fh) <- liftIO $ openFPath (ecuFilePath (crCU modNm cr)) ReadMode False
      ; tokens  <- liftIO $ offsideScanHandle scanOpts fn fh
      ; let (res,_) = parseOffsideToResMsgsStopAtErr parser tokens
      ; cpUpdCU modNm (store res)
      }
%%]

%%[50.cpParseHsImport export(cpParseHsImport)
cpParseHsImport :: EHCCompileRunner m => HsName -> EHCompilePhaseT m ()
cpParseHsImport modNm
  = do { cr <- get
       ; let (_,opts) = crBaseInfo' cr
       ; cpParseOffsideStopAtErr (HSPrs.pAGItfImport opts) (hsScanOpts opts) ecuStoreHS modNm
       }
%%]

%%[99 -50.cpParseHsImport export(cpParseHsImport)
cpParseHsImport :: EHCCompileRunner m => Bool -> HsName -> EHCompilePhaseT m ()
cpParseHsImport litmode modNm
  = do { cr <- get
       ; let (_,opts) = crBaseInfo' cr
       ; cpParseOffsideStopAtErr (HSPrs.pAGItfImport opts) ((hsScanOpts opts) {ScanUtils.scoLitmode = litmode}) ecuStoreHS modNm
       }
%%]

%%[(8 corein) export(cpParseCoreWithFPath)
cpParseCoreWithFPath :: EHCCompileRunner m => Maybe FPath -> HsName -> EHCompilePhaseT m ()
cpParseCoreWithFPath mbFp modNm
  = do (_,opts) <- gets crBaseInfo'
       cpParseWithFPath scanHandle parseToResMsgs (cpSetLimitErrsWhen 5 "Parse Core") CorePrs.pCModule (coreScanOpts opts) ecuStoreCore mbFp modNm

{-
cpParseCore :: EHCCompileRunner m => HsName -> EHCompilePhaseT m ()
cpParseCore modNm
  = do { cr <- get
       ; let  (ecu,_,opts,fp) = crBaseInfo modNm cr
              fpC     = fpathSetSuff Cfg.suffixDotlessInputOutputTextualCore fp
       ; cpMsg' modNm VerboseALot "Parsing" Nothing fpC
       ; errs <- cpParsePlainToErrs CorePrs.pCModule (coreScanOpts opts) ecuStoreCore fpC modNm
       ; when (ehcDebugStopAtCoreError opts)
              (cpSetLimitErrsWhen 5 "Parse Core (of previous compile) of module" errs)
       ; return ()
       }
-}
%%]

%%[5020 export(cpParseHI)
cpParseHI :: EHCCompileRunner m => HsName -> EHCompilePhaseT m ()
cpParseHI modNm
  = do { cr <- get
       ; let  (ecu,_,opts,fp) = crBaseInfo modNm cr
%%[[50
              fpH     = fpathSetSuff "hi" fp
%%][99
              -- if outputdir is specified, use that location to possibly read hi from.
              fpH     = mkInOrOutputFPathFor (InputFrom_Loc $ ecuFileLocation ecu) opts modNm fp "hi"
%%]]
       ; cpMsg' modNm VerboseALot "Parsing" Nothing fpH
       ; fnfh <- liftIO $ openFPath fpH ReadMode False
       ; errs <- cpParsePlainWithHandleToErrs HIPrs.pAGItf (hiScanOpts opts) ecuStorePrevHI fnfh modNm
       ; when (ehcDebugStopAtHIError opts)
              (cpSetLimitErrsWhen 5 "Parse HI (of previous compile) of module" errs)
       ; return ()
       }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: Binary reading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 export(cpDecodeHIInfo)
cpDecodeHIInfo :: EHCCompileRunner m => HsName -> EHCompilePhaseT m ()
cpDecodeHIInfo modNm
  = do { cr <- get
       ; let  (ecu,_,opts,fp) = crBaseInfo modNm cr
%%[[50
              fpH     = fpathSetSuff "hi" fp
%%][99
              -- if outputdir is specified, use that location to possibly read hi from.
              fpH     = mkInOrOutputFPathFor (InputFrom_Loc $ ecuFileLocation ecu) opts modNm fp "hi"
%%]]
       ; cpMsg' modNm VerboseALot "Decoding" Nothing fpH
       ; hiinfo <- liftIO $
           CE.catch (do { i <- getSGetFile (fpathToStr fpH) (HI.sgetHIInfo opts)
                               -- getSerializeFile (fpathToStr fpH)
                               -- Bin.getBinaryFPath fpH
                        ; return i
                        })
                    (\(_ :: SomeException) -> return $ HI.emptyHIInfo {HI.hiiValidity = HI.HIValidity_Absent})
       ; when (ehcOptVerbosity opts > VerboseALot)
              (do { liftIO $ putPPLn (pp hiinfo)
                  })
%%[[99
       ; let canCompile = crModCanCompile modNm cr
%%]]
       ; case HI.hiiValidity hiinfo of
%%[[99
           HI.HIValidity_WrongMagic | not canCompile
             -> cpSetLimitErrsWhen 1 "Read HI"
                  [rngLift emptyRange Err_WrongMagic
                     (show modNm)
                     (fpathToStr fpH)
                  ]
           HI.HIValidity_Inconsistent | not canCompile
             -> cpSetLimitErrsWhen 1 "Read HI (of previous compile) of module"
                  [rngLift emptyRange Err_InconsistentHI
                     (show modNm)
                     (fpathToStr fpH)
                     [Sig.timestamp, Cfg.installVariant opts, show $ ehcOptTarget opts, show $ ehcOptTargetFlavor opts]
                     [HI.hiiSrcTimeStamp hiinfo   , HI.hiiCompiler hiinfo  , show $ HI.hiiTarget hiinfo, show $ HI.hiiTargetFlavor hiinfo]
                  ]
%%]]
           _ -> cpUpdCU modNm (ecuStorePrevHIInfo {-- $ HI.hiiPostCheckValidity opts -} hiinfo)
       }
%%]

%%[50
-- | Decode from serialized file and store result in the compileunit for the module modNm
cpDecode :: (EHCCompileRunner m, Serialize x) => Maybe String -> EcuUpdater x -> HsName -> EHCompilePhaseT m ()
cpDecode mbSuff store modNm
  = do { cr <- get
       ; let  (ecu,_,opts,fp) = crBaseInfo modNm cr
              fpC     = maybe id fpathSetSuff mbSuff fp
       ; cpMsg' modNm VerboseALot "Decoding" Nothing fpC
       ; x <- liftIO $ getSerializeFile (fpathToStr fpC)
       ; cpUpdCU modNm (store x)
       }
%%]

%%[(50 codegen grin) export(cpDecodeGrin)
cpDecodeGrin :: EHCCompileRunner m => HsName -> EHCompilePhaseT m ()
cpDecodeGrin = cpDecode (Just "grin") ecuStoreGrin
%%]

%%[(50 codegen) export(cpDecodeCore)
cpDecodeCore :: EHCCompileRunner m => Maybe String -> HsName -> EHCompilePhaseT m ()
cpDecodeCore suff = cpDecode suff ecuStoreCore
%%]

%%[(50 corerun) export(cpDecodeCoreRun)
cpDecodeCoreRun :: EHCCompileRunner m => Maybe String -> HsName -> EHCompilePhaseT m ()
cpDecodeCoreRun suff = cpDecode suff ecuStoreCore
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: on top of parsing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 export(cpGetPrevHI)
cpGetPrevHI :: EHCCompileRunner m => HsName -> EHCompilePhaseT m ()
cpGetPrevHI modNm
  = do { cr <- get
       ; cpMsg modNm VerboseDebug "cpGetPrevHI"
       ; let  ecu        = crCU modNm cr
       -- ; when (isJust (ecuMbHITime ecu))
       --        (cpParseHI modNm)
       ; when (isJust (ecuMbHIInfoTime ecu))
              (cpDecodeHIInfo modNm)
       }
%%]

%%[(50 codegen) export(cpGetPrevCore)
cpGetPrevCore :: EHCCompileRunner m => HsName -> EHCompilePhaseT m Core.CModule
cpGetPrevCore modNm
  = do { cr <- get
       ; cpMsg modNm VerboseDebug "cpGetPrevCore"
       ; let  ecu    = crCU modNm cr
       ; when (isJust (ecuMbCoreTime ecu) && isNothing (ecuMbCore ecu))
              (cpDecodeCore (Just Cfg.suffixDotlessBinaryCore) modNm)
              -- (cpParseCore modNm)
       ; fmap (fromJust . ecuMbCore) $ gets (crCU modNm)
       }
%%]

%%[(50 corerun) export(cpGetPrevCoreRun)
cpGetPrevCoreRun :: EHCCompileRunner m => HsName -> EHCompilePhaseT m CoreRun.Mod
cpGetPrevCoreRun modNm
  = do { cr <- get
       ; cpMsg modNm VerboseDebug "cpGetPrevCoreRun"
       ; let  ecu    = crCU modNm cr
       ; when (isJust (ecuMbCoreRunTime ecu) && isNothing (ecuMbCoreRun ecu))
              (cpDecodeCoreRun (Just Cfg.suffixDotlessBinaryCoreRun) modNm)
       ; fmap (fromJust . ecuMbCoreRun) $ gets (crCU modNm)
       }
%%]

%%[(50 codegen grin) export(cpGetPrevGrin)
cpGetPrevGrin :: EHCCompileRunner m => HsName -> EHCompilePhaseT m ()
cpGetPrevGrin modNm
  = do { cr <- get
       ; cpMsg modNm VerboseDebug "cpGetPrevGrin"
       ; let  ecu    = crCU modNm cr
       ; when (isJust (ecuMbGrinTime ecu) && isNothing (ecuMbGrin ecu))
              (cpDecodeGrin modNm) -- (cpParseGrin modNm)
       }
%%]


