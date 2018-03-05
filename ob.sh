#!/bin/bash
#cd ..
#javac -cp lib/http/lib/httpclient-4.3.1.jar:lib/http/lib/httpcore-4.3.jar:lib/http/lib/commons-logging-1.1.3.jar:lib/pusher-java-client-0.2.2-jar-with-dependencies.jar:lib/gson-2.2.4.jar:lib/apache-log4j-1.2.17/log4j-1.2.17.jar:src:. src/*.java
#java -ea -cp lib/http/lib/httpclient-4.3.1.jar:lib/http/lib/httpcore-4.3.jar:lib/http/lib/commons-logging-1.1.3.jar:lib/pusher-java-client-0.2.2-jar-with-dependencies.jar:lib/gson-2.2.4.jar:lib/apache-log4j-1.2.17/log4j-1.2.17.jar:src:. OrderBookStream 
#cd -

java -jar target/ob-jar-with-dependencies.jar


    if (lastDecay_ == 0)
    {
        lastDecay_ = clock_ / decayInterval_ * decayInterval_;
    }
    if (clock_ - lastDecay_ < decayInterval_)
        return;

    lastDecay_ = lastDecay_ + decayInterval_;

    portsig_st_ =0.0;
    portsig_mt_ =0.0;
    portsig_lt_ =0.0;
    double counter =0.0;
    Instruments *iu = Instruments::instance();
    Instruments::SymbolInstrumentMapIter it = iu->begin(), eIt = iu->end();
    for (; it != eIt; ++it)
    {
        tradeHistory_[it->second].Book_Sig_Dyn_ *= rho_bk_;
        tradeHistory_[it->second].Book_Sig_Dyn_lt_ *= rho_bk_lt_;

        double vwap_sig_st = 0;
        double vwap_sig_mt = 0;
        double vwap_sig_lt = 0;
        if(tradeHistory_[it->second].trades_[0].price_.px()>0 && tradeHistory_[it->second].vwap_st_>0)
            vwap_sig_st = ((tradeHistory_[it->second].trades_[0].price_.px()) - (tradeHistory_[it->second].vwap_st_))/tradeHistory_[it->second].range_st_;
        if(tradeHistory_[it->second].trades_[0].price_.px()>0 && tradeHistory_[it->second].vwap_mt_>0)
            vwap_sig_mt = ((tradeHistory_[it->second].trades_[0].price_.px()) - (tradeHistory_[it->second].vwap_mt_))/tradeHistory_[it->second].range_st_;
        if(tradeHistory_[it->second].trades_[0].price_.px()>0 && tradeHistory_[it->second].vwap_lt_>0)
            vwap_sig_lt = ((tradeHistory_[it->second].trades_[0].price_.px()) - (tradeHistory_[it->second].vwap_lt_))/tradeHistory_[it->second].range_st_;
        portsig_st_ += vwap_sig_st;
        portsig_mt_ += vwap_sig_mt;
                counter ++;
    }
    if(counter >=1)
    {
        portsig_st_ /= counter;
        portsig_mt_ /= counter;
        portsig_lt_ /= counter;
    }

#include "Grape.h"

#include <fstream>
#include <sstream>
#include <math.h>
#include <Poco/Util/IniFileConfiguration.h>
#include <Poco/NumberParser.h>
#include <Poco/StringTokenizer.h>

#define DEBUG

void Grape::init()
{
    BaseAlgo::init();

    Instruments *iu = Instruments::instance();
    Instruments::SymbolInstrumentMapIter it = iu->begin(), eIt = iu->end();
    for (; it != eIt; ++it)
    {
    	tradeHistory_[it->second].setPeriod(300);
    }

    Poco::AutoPtr<Poco::Util::IniFileConfiguration> pConf = new Poco::Util::IniFileConfiguration(config_);
    const std::string prefix = "Grape";
    std::string key;
    key = prefix + ".Route";
    if (pConf->has(key))
    {
        route_ = pConf->getString(key);
    }
    key = prefix + ".ImbThreshold";
    if (pConf->has(key))
    {
        imbThreshold_ = pConf->getInt(key);
    }
    std::string coeffFile;
    key = prefix + ".DayCoeffFile";
    if (pConf->has(key))
    {
        coeffFile = pConf->getString(key);
        loadCoeffs(dayCoeffs_, coeffFile);
    }
    else
    {
        std::cerr << "Missing day coeff file\n";
        exit(0);
    }
    key = prefix + ".CloseCoeffFile";
    if (pConf->has(key))
    {
        coeffFile = pConf->getString(key);
        loadCoeffs(closeCoeffs_, coeffFile);
    }
    else
    {
        std::cerr << "Missing close coeff file\n";
        exit(0);
    }

    key = prefix + ".CloseStartTime";
    if (pConf->has(key))
    {
        closeStartTime_ = pConf->getInt(key);
        closeStartTime_ = closeStartTime_ * 1000;
    }

    key = prefix + ".CloseEndTime";
    if (pConf->has(key))
    {
        closeEndTime_ = pConf->getInt(key);
        closeEndTime_ = closeEndTime_ * 1000;
    }

    key = prefix + ".SignalStartTime";
    if (pConf->has(key))
    {
        signalStartTime_ = pConf->getInt(key);
        signalStartTime_ = signalStartTime_ * 1000;
    }

    key = prefix + ".FreezeStartTime";
    if (pConf->has(key))
    {
        freezeStartTime_ = pConf->getInt(key);
        freezeStartTime_ = freezeStartTime_ * 1000;
    }

    key = prefix + ".FreezeEndTime";
    if (pConf->has(key))
    {
        freezeEndTime_ = pConf->getInt(key);
        freezeEndTime_ = freezeEndTime_ * 1000;
    }

    key = prefix + ".CloseStage1Time";
    if (pConf->has(key))
    {
        closeStage1Time_ = pConf->getInt(key);
        closeStage1Time_ = closeStage1Time_ * 1000;
    }

    std::string riskFile;
    key = prefix + ".RiskFile";
    if (pConf->has(key))
    {
        riskFile = pConf->getString(key);
        loadRisk(dayCoeffs_, riskFile);
    }
    else
    {
        std::cerr << "Missing risk file\n";
        exit(0);
    }

    key = prefix + ".RangeCheck";
    if (pConf->has(key))
    {
        rangeCheck_ = pConf->getBool(key);
    }

    key = prefix + ".RevControl";
    if (pConf->has(key))
    {
        revControl_ = pConf->getBool(key);
    }

    key = prefix + ".VenueControl";
    if (pConf->has(key))
    {
        venueControl_ = pConf->getBool(key);
    }

    key = prefix + ".LiquidatorOn";
    if (pConf->has(key))
    {
        liquidatorOn_ = pConf->getBool(key);
    }

    key = prefix + ".StLen";
    if (pConf->has(key))
    {
        stLen_ = pConf->getInt(key);
    }
    key = prefix + ".MtLen";
    if (pConf->has(key))
    {
        mtLen_ = pConf->getInt(key);
    }

    key = prefix + ".IncreasePos";
    if (pConf->has(key))
    {
        increasePosEnabled_ = pConf->getBool(key);
    }

    key = prefix + ".TickCancel";
    if (pConf->has(key))
    {
        tickCancelEnabled_ = pConf->getBool(key);
    }

    key = prefix + ".SigThreshold";
    if (pConf->has(key))
    {
        sigThreshold_ = pConf->getDouble(key);
    }

    key = prefix + ".UseEquote";
    if (pConf->has(key))
    {
        useEquote_ = pConf->getBool(key);
    }

    if (useEquote_)
    {
        key = prefix + ".ParityBuyStrategy";
        if (pConf->has(key))
        {
            parityBuyStrategy_ = pConf->getString(key);
        }
        key = prefix + ".ParitySellStrategy";
        if (pConf->has(key))
        {
            paritySellStrategy_ = pConf->getString(key);
        }
    }

}

void Grape::loadRisk(std::map<Instrument*, Coefficients>& coeffs, const std::string& file)
{
    std::ifstream   stream(file.c_str());
    if(!stream) {
        std::cerr << "Cannot open risk file: " << file << "\n";
        exit(0);
    }
    std::string     line;
    while(getline(stream, line)) {
        if(line.empty())  continue;
        Poco::StringTokenizer tokenizer(line, " ", Poco::StringTokenizer::TOK_TRIM);
        assert(tokenizer.count() == 6);
        std::string symbol = tokenizer[0];
        Instrument* inst = Instruments::instance()->getInstrument(symbol);
        if (!inst)
        {
            std::cerr << "Skipping Coeff for Symbol " << symbol << "\n";
            continue;
        }

        Coefficients& coeff = coeffs[inst];
        coeff.statbook_coeff_ = Poco::NumberParser::parseFloat(tokenizer[1]);
        coeff.dynabookLt_coeff_ = Poco::NumberParser::parseFloat(tokenizer[2]);
        coeff.lasttick_coeff_ = Poco::NumberParser::parseFloat(tokenizer[3]);
        coeff.spymt_coeff_ = Poco::NumberParser::parseFloat(tokenizer[4]);
        coeff.qqqmt_coeff_ = Poco::NumberParser::parseFloat(tokenizer[5]);
   }
}
void Grape::loadCoeffs(std::map<Instrument*, Coefficients>& coeffs, const std::string& file)
{
    std::ifstream   stream(file.c_str());
    if(!stream) {
        std::cerr << "Cannot open coeff file: " << file << "\n";
        exit(0);
    }
    std::string     line;
    while(getline(stream, line)) {
        if(line.empty())  continue;
        Poco::StringTokenizer tokenizer(line, " ", Poco::StringTokenizer::TOK_TRIM);
        //assert(tokenizer.count() == 11);
        if(tokenizer.count() != 11 && tokenizer.count() != 8)
        {
            std::cerr << "Cannot open coeff file: " << file << "\n";
            exit(0);
        }
        std::string symbol = tokenizer[0];
        Instrument* inst = Instruments::instance()->getInstrument(symbol);
        if (!inst)
        {
            std::cerr << "Skipping Coeff for Symbol " << symbol << "\n";
            continue;
        }

        Coefficients& coeff = coeffs[inst];
        coeff.tradeSize_ = Poco::NumberParser::parse(tokenizer[1]);
        coeff.maxShares_ = Poco::NumberParser::parse(tokenizer[2]);
        coeff.minSupportSz_ = Poco::NumberParser::parse(tokenizer[3]);
        coeff.sizeThresh_ = Poco::NumberParser::parseFloat(tokenizer[4]);
        coeff.useSignal_ = Poco::NumberParser::parse(tokenizer[5]);
        coeff.aggressiveOut_ = Poco::NumberParser::parse(tokenizer[6]);
        coeff.numLadder_ = Poco::NumberParser::parse(tokenizer[7]);
        if(tokenizer.count() == 11)
        {
			coeff.stLenMax_ = Poco::NumberParser::parseFloat(tokenizer[8]);
			coeff.mtLenMax_ = Poco::NumberParser::parseFloat(tokenizer[9]);
			coeff.ltLenMax_ = Poco::NumberParser::parseFloat(tokenizer[10]);
        }

    }
}

void Grape::onBookUpdate(Instrument* inst, int timestamp, const BkLevelNode* order, Price4& px,
			OrderBook::UpdateReason reason, int szDelta, int orderDelta)
{
    BaseAlgo::onBookUpdate(inst, timestamp, order, px, reason, szDelta, orderDelta);
    //MTLOG("ARCA book\n");
    //inst->limeBook_->subBook("ARCA").printBook(5, true);
    //MTLOG("NYOU book\n");
    //inst->limeBook_->subBook("NYOU").printBook(5, true);
    //MTLOG("Combined\n");
    //inst->limeBook_->printBook(5, true);

    if(liquidatorOn_)
    	inst->reduceOnly_ = true;
    if (!frozen && clock_ > freezeStartTime_ && clock_ < freezeEndTime_ - 1000)
    {
        MTLOG("Freezing Algo...\n");
        frozen = true;
        Instruments *iu = Instruments::instance();
        Instruments::SymbolInstrumentMapIter it = iu->begin(), eIt = iu->end();
        for (; it != eIt; ++it)
        {
            om_->cancelPendingOrders(it->second);
            it->second->disableTrading();
        }
    }
    else if (frozen && clock_ > freezeEndTime_)
    {
        MTLOG("Resuming Algo...\n");
        frozen = false;
        Instruments *iu = Instruments::instance();
        Instruments::SymbolInstrumentMapIter it = iu->begin(), eIt = iu->end();
        for (; it != eIt; ++it)
        {
            it->second->enableTrading();
        }
    }

    if (clock_ > closeEndTime_ && !closeBatchCanceled_)
    {
        MTLOG("Canceling Non-Closing Orders...\n");
    	closeBatchCanceled_ = true;
        Instruments *iu = Instruments::instance();
        Instruments::SymbolInstrumentMapIter it = iu->begin(), eIt = iu->end();
        for (; it != eIt; ++it)
        {
            cancelBadClosingOrders(it->second);
        }
    }

    if (clock_ > closeStage1Time_ && !stage1CoeffUpdated_)
    {
        MTLOG("Change to stage1 coefficients.\n");
        stage1CoeffUpdated_ = true;
        for(std::map<Instrument*, Coefficients>::iterator iter = closeCoeffs_.begin(); iter != closeCoeffs_.end(); ++iter)
        {
            iter->second.tradeSize_ = std::min(iter->second.tradeSize_, 200);
        }
    }

    if(clock_ > closeStartTime_)
    	increasePosEnabled_ = false;

    if (!inst->enabled_)
    	return;

    if (!inst->opened_)
        return;

    if(clock_ <= (9*3600+30*60)*1000 || clock_ >= 16*3600*1000)
    	return;

    Signal& signal = signals_[inst];

    decaySignals();

    Coefficients& coeff = getCoeffs(inst);

    Price4 bestBid = inst->limeBook_->book().getPrice(1, 1);
    Price4 bestAsk = inst->limeBook_->book().getPrice(-1, 1);
    int bidSize = inst->limeBook_->book().getSize(1, 1);
    int askSize = inst->limeBook_->book().getSize(-1, 1);


    if (bestBid >= bestAsk)
    {
        ++numBookCrosses_;
        return;
    }
#if 1
    Price4 arcabid= inst->limeBook_->subBook("ARCA").getPrice(1,1);
    Price4 arcaask= inst->limeBook_->subBook("ARCA").getPrice(-1,1);
    Price4 nyoubid= inst->limeBook_->subBook("NYOU").getPrice(1,1);
    Price4 nyouask= inst->limeBook_->subBook("NYOU").getPrice(-1,1);
#endif

	signal.bestPx_[0] = bestBid.px();
	signal.bestPx_[1] = bestAsk.px();
	signal.bestSz_[0] = bidSize;
	signal.bestSz_[1] = askSize;

	if(clock_ > lastClock_ + 60*1000)
	{
		portVwapSig_ = 0.0;
		double counter = 0.0;
		Instruments *iu = Instruments::instance();
		Instruments::SymbolInstrumentMapIter it = iu->begin(), eIt = iu->end();
		for (; it != eIt; ++it)
		{
			signals_[it->second].totalValue_ *= 0.99;
			signals_[it->second].totalVolume_ *= 0.99;
	        if(signal.totalVolume_ >10.0)
	        {
	        	signal.vwapPx_ = signal.totalValue_/signal.totalVolume_;
	        	signal.vwapSig_ = (log(px.px()) - log(signal.vwapPx_))/(0.001);
	        }

			portVwapSig_ += signals_[it->second].vwapSig_;
			counter ++;
		}
		portVwapSig_ /= std::max(1.0, counter);
		lastClock_ = clock_;
	}

	if (signal.bestPx_[0] != signal.prevBestPx_[0] || signal.bestSz_[0] != signal.prevBestSz_[0]
	    || signal.bestPx_[1] != signal.prevBestPx_[1] || signal.bestSz_[1] != signal.prevBestSz_[1])
	{
		for (int i = 0; i < 2; ++i)
		{
			if (signal.prevBestPx_[i] > 0)
			{
				signal.emaPxSt_[i] = signal.emaPxSt_[i] == 0 ? signal.prevBestPx_[i] :
						signal.emaPxSt_[i] * coeff.emaStDecay_ + signal.prevBestPx_[i] * (1 - coeff.emaStDecay_);
				signal.emaSzSt_[i] = signal.emaSzSt_[i] == 0 ? signal.prevBestSz_[i] :
						signal.emaSzSt_[i] * coeff.emaStDecay_ + signal.prevBestSz_[i] * (1 - coeff.emaStDecay_);
				signal.emaPxLt_[i] = signal.emaPxLt_[i] == 0 ? signal.prevBestPx_[i] :
						signal.emaPxLt_[i] * coeff.emaLtDecay_ + signal.prevBestPx_[i] * (1 - coeff.emaLtDecay_);
				signal.emaSzLt_[i] = signal.emaSzLt_[i] == 0 ? signal.prevBestSz_[i] :
						signal.emaSzLt_[i] * coeff.emaLtDecay_ + signal.prevBestSz_[i] * (1 - coeff.emaLtDecay_);
			}
		}

#if 0
		MTLOG("Sym:" << inst->sym_
	            << " EMAPXST: " << signal.emaPxSt_[0] << " " << signal.emaPxSt_[1]
	            << " EMASZST: " << signal.emaSzSt_[0] << " " << signal.emaSzSt_[1]
	            << " EMAPXLT: " << signal.emaPxLt_[0] << " " << signal.emaPxLt_[1]
	            << " EMASZLT: " << signal.emaSzLt_[0] << " " << signal.emaSzLt_[1] << "\n");
#endif

	    computeStaticBook(inst, signal);
	    computeSignal(inst, signal);

	    double curMid = (signal.bestPx_[0] + signal.bestPx_[1]) * 0.5;
	    double prevMid = (signal.prevBestPx_[0] + signal.prevBestPx_[1]) * 0.5;
	    if (prevMid == 0 || curMid==0 )
	    {
	        signal.decayRetSt_ = 0;
	        signal.decayRetMt_ = 0;
	        signal.decayRetLt_ = 0;
	    }
	    else
	    {
	        signal.decayRetSt_ += log(curMid)-log(prevMid);
	        signal.decayRetMt_ += log(curMid)-log(prevMid);
	        signal.decayRetLt_ += log(curMid)-log(prevMid);
	    }

#if 0
	    //dump signal
		if(clock_ > lastClock2_ + 1*1000 && clock_ >=34500*1000)
		{
		    if (!midFp_)
		    {
		        std::string filename = std::string("signals/sig") + "." + "txt";
		        midFp_ = fopen(filename.c_str(), "w");
		        if (!midFp_)
		        {
		            std::cerr << "Failed to open output file " << filename << "\n";
		            exit(0);
		        }
		    }
		    Instruments *iu = Instruments::instance();
		    Instruments::SymbolInstrumentMapIter it = iu->begin(), eIt = iu->end();
		    for (; it != eIt; ++it)
		    {
		        Signal& signal = signals_[it->second];
		        fprintf(midFp_, "%s\t %d   %6.6f  %6.6f  %6.6f  %6.6f  %6.6f  %6.6f  %6.6f  %6.6f  %6.6f  %6.6f  %6.6f", it->second->sym_,
		        		int(clock_/1000),
		        		signal.bestPx_[0], signal.bestPx_[1], signal.bisi_,
		        		signal.lastTickDir_, signal.staticBook_,
		                signal.dynaBook_ , signal.dynaBookLt_,
		                signal.decayRetSt_, signal.decayRetMt_, signal.decayRetLt_,
		                signal.vwapSig_ - portVwapSig_);
			    fprintf(midFp_, "\n");
		    }
			lastClock2_ = clock_;
		}



#endif



#if 1
	    for (int side = 0; side < 2; ++side)
	    {
            int dir = 1 - 2 * side;

            Price4 tradePx = (side == 0) ? bestBid : bestAsk;
		    int pending = getPendingOrders(inst, dir, tradePx, true);
            //int pending = getPendingOrders(inst, dir);
            double sigThresholdOut_ = sigThreshold_;
            double sigThresholdIn_ = sigThreshold_;

#if 1
            if(abs(inst->curPos_) > 0.5*inst->posLimit_)
            {
            	sigThresholdOut_ = 0.75*sigThreshold_;
            	sigThresholdIn_ = 1.5*sigThreshold_;
            }
            double aa = tradeHistory_[inst].max_st_ - tradeHistory_[inst].min_st_;
            //double bb = tradeHistory_[inst].max_mt_ - tradeHistory_[inst].min_mt_;
            sigThresholdOut_ *= std::max(0.75, std::min(1.5,(aa/0.04)));
            sigThresholdIn_ *= std::max(0.75, std::min(1.5,(aa/0.04)));

            sigThresholdOut_ *= std::max(0.75, std::min(3.0,(tradeHistory_[inst].min_st_/15.0)));
            sigThresholdIn_ *= std::max(1.0, std::min(3.0,(tradeHistory_[inst].min_st_/15.0)));

            if(om_->getTotalImb() >1.0*imbThreshold_ && dir==1)
            {
            	sigThresholdOut_ *= 1.33;
            }
            else if(om_->getTotalImb() >1.0*imbThreshold_ && dir==-1)
            {
            	sigThresholdOut_ *= 0.75;
            }
            else if(om_->getTotalImb() < -1.0*imbThreshold_ && dir==1)
            {
            	sigThresholdOut_ *= 0.75;
            }
            else if(om_->getTotalImb() < -1.0*imbThreshold_ && dir==-1)
            {
            	sigThresholdOut_ *= 1.33;
            }
#endif


            bool signalOK = false;
            if (coeff.useSignal_ > 0)
            {
                if(dir==1 && pending && inst->curPos_ < 0 && signal.signal_ > 0.75*sigThresholdOut_ )
                	signalOK = true;
                else if(dir==1 && !pending && inst->curPos_ < 0 && signal.signal_ >=  sigThresholdOut_ )
					signalOK = true;
                else if(dir==1 && pending && inst->curPos_ >= 0 && signal.signal_ > 0.75*sigThresholdIn_ && signal.dynaBookLt_ >=sigThresholdDyn_ )
					signalOK = true;
                else if(dir==1 && !pending && inst->curPos_ >= 0 && signal.signal_ > sigThresholdIn_ && signal.dynaBookLt_ >= sigThresholdDyn_ )
					signalOK = true;
                else if(dir==-1 && pending && inst->curPos_ > 0 && signal.signal_ < -0.75*sigThresholdOut_ )
                	signalOK = true;
                else if(dir==-1 && !pending && inst->curPos_ > 0 && signal.signal_ <= -sigThresholdOut_ )
					signalOK = true;
                else if(dir==-1 && pending && inst->curPos_ <= 0 && signal.signal_ < -0.75*sigThresholdIn_ && signal.dynaBookLt_ <=-sigThresholdDyn_ )
					signalOK = true;
                else if(dir==-1 && !pending && inst->curPos_ <= 0 && signal.signal_ < -sigThresholdIn_ && signal.dynaBookLt_ <=- sigThresholdDyn_)
					signalOK = true;

            }
            else
                signalOK = true;

	        bool getOut = (dir == 1 && inst->curPos_ < 0) || (dir == -1 && inst->curPos_ > 0);

	        if (inst->reduceOnly_ && !getOut)
	            continue;

	        double ThreshOut_ = 0.5;
	        double ThreshIn_ = 1.0;
	        //ThreshOut_ = ThreshIn_ ;
#if 1
            if(abs(inst->curPos_) > 0.5*inst->posLimit_)
            {
            	ThreshOut_ = 0.5;
            	ThreshIn_ = 1.25;
            }
#endif
	        bool supportOK = false;
	    	if (getOut)
	    	    supportOK = signal.bestSz_[side] > std::min(ThreshOut_ * coeff.minSupportSz_, 500.0);
	    	else
	    	    supportOK = signal.bestSz_[side] > ThreshIn_ * coeff.minSupportSz_;

	    	// double refSize = (signal.emaSzLt_[0] + signal.emaSzLt_[1]) * 0.5;
	    	double refSize1 = signal.emaSzLt_[side];
	    	double refSize2 = signal.emaSzSt_[side];
	    	if(!getOut)
	    	{
	    		//refSize1 = std::max(signal.emaSzLt_[0] , signal.emaSzLt_[1]);
	    		//refSize2 = std::max(signal.emaSzSt_[0] , signal.emaSzSt_[1]);
	    	}
	    	if (getOut)
	    	{
	    	    refSize1 = ThreshOut_ * refSize1;
	    	    refSize2 = ThreshOut_ * refSize2;
	    	}
	    	else
	    	{
	    	    refSize1 = ThreshIn_ * refSize1;
	    	    refSize2 = ThreshIn_ * refSize2;
	    	}
	    	bool emaGuardOK =
	    	        signal.bestSz_[side] > coeff.sizeThresh_ * refSize1 &&
	    	        signal.bestSz_[side] > coeff.sizeThresh_ * refSize2 &&
	    			(fabs(signal.bestPx_[side] - signal.emaPxLt_[side]) < coeff.pxDiffThresh_ || getOut);


	    	int tradeSize = 0;
	        if(clock_ > closeStartTime_ && getOut)
	        	tradeSize = std::min(2*coeff.tradeSize_, abs(inst->curPos_));
	        else if (getOut)
	    	    tradeSize = std::min(1*coeff.tradeSize_, abs(inst->curPos_));
	    	else
	    	    tradeSize = coeff.tradeSize_;

	    	bool aggressiveOut = getOut && (coeff.aggressiveOut_ || (clock_ > closeEndTime_));

	    	//new add
	    	if (tickCancelEnabled_)
	    	{
                if((dir == 1 && signal.lastTrade_ == bestAsk && signal.lastSz_ >= 2*signal.avgSz_ && signal.lastSz_ >=400.0)
                        || (dir == -1 && signal.lastTrade_ == bestBid && signal.lastSz_ >= 2*signal.avgSz_ && signal.lastSz_ >=400.0))
                {
                    if (!signalOK)
                        ++tickSigFlips_;
                    signalOK = true;

                    bool prevSupport = supportOK;
                    if (getOut)
                        supportOK = signal.bestSz_[side] > std::min(0.25 * coeff.minSupportSz_, 200.0);
                    else
                        supportOK = signal.bestSz_[side] > 0.5*coeff.minSupportSz_;
                    if (!prevSupport && supportOK)
                        ++tickSupportFlips_;

                    bool prevEMAOK = emaGuardOK;
                    emaGuardOK =
                                        signal.bestSz_[side] > 0.5*coeff.sizeThresh_ * refSize1 &&
                                        signal.bestSz_[side] > 0.5*coeff.sizeThresh_ * refSize2 &&
                                        (fabs(signal.bestPx_[side] - signal.emaPxLt_[side]) < coeff.pxDiffThresh_ || getOut);
                    if (emaGuardOK && !prevEMAOK)
                        ++tickEMAFlips_;
                }
	    	}

	    	if(coeff.useSignal_ != 2)
	    	{
	        	signal.ladderBuy_ = true;
	        	signal.ladderSell_ = true;
	    	}


	    	if(rangeCheck_ && coeff.useSignal_ == 2 && clock_ < closeStartTime_ )
	    	{
	    		TradeHistory& tradeHistory = tradeHistory_[inst];

	    		// 0.1, 0.1 the best with rev control
	    		if(((dir==1 && inst->curPos_ >= 0) || (dir== -1 && inst->curPos_ <= 0)) &&
	    				(tradeHistory.max_st_ - tradeHistory.min_st_ > dayCoeffs_[inst].stLenMax_
	    						|| tradeHistory.max_mt_ - tradeHistory.min_mt_ > dayCoeffs_[inst].mtLenMax_
								|| tradeHistory.max_lt_ - tradeHistory.min_lt_ > dayCoeffs_[inst].ltLenMax_))
	    		{
	    			signalOK = false;
	    		}
	    		if((int)tradeHistory.size() < stLen_ )
	    			signalOK = false;

	    		//if(((dir==1 && inst->curPos_ >= 0) || (dir== -1 && inst->curPos_ <= 0)) && signal.bestPx_[1] - signal.bestPx_[0] < 0.011)
	    			//signalOK = false;

	    		//reversion control
	    		if(revControl_)
	    		{
					if(signalOK == true && tradeHistory.max_st_ - tradeHistory.min_st_ > 0.031) //0.031 the best
					{
						//0.25, 0.75 the best, result 8590196/2899.55/0.000337541
					if((dir==1 && inst->curPos_ >= 0) && (signal.bestPx_[0] <0.25*tradeHistory.max_st_ + 0.75* tradeHistory.min_st_ ))
							signalOK = false;
					else if((dir== -1 && inst->curPos_ <= 0) && (signal.bestPx_[1] >0.25*tradeHistory.min_st_ + 0.75* tradeHistory.max_st_ ))
							signalOK = false;
					}
	    		}
	        	//results
	        	// max_st-min_st > 0.1; max_mt-min_mt > 0.1, 0.031, 0.25/0.75, 8590196/2899.55/0.000337541
	        	// no rev control: 0.05, 0.1, 0.5;


	        	//for ladders
	        	signal.ladderBuy_ = true;
	        	signal.ladderSell_ = true;

                if((int)tradeHistory.size() < stLen_ )
                {
                	signal.ladderBuy_ = false;
                	signal.ladderSell_ = false;
                }
	        	if(tradeHistory.max_st_ - tradeHistory.min_st_ > dayCoeffs_[inst].stLenMax_-0.01
	    						|| tradeHistory.max_mt_ - tradeHistory.min_mt_ > dayCoeffs_[inst].mtLenMax_-0.01
								|| tradeHistory.max_lt_ - tradeHistory.min_lt_ > dayCoeffs_[inst].ltLenMax_-0.01)
	        	{
	        		signal.ladderBuy_ = false;
	        		signal.ladderSell_ = false;
	        	}

	        	if(tradeHistory.max_st_ - tradeHistory.min_st_ > 0.031 && signal.bestPx_[0] - 0.01 <0.25*tradeHistory.max_st_ + 0.75* tradeHistory.min_st_ )
	        		signal.ladderBuy_ = false;
	        	if(tradeHistory.max_st_ - tradeHistory.min_st_ > 0.031 && signal.bestPx_[1] +0.01>0.25*tradeHistory.min_st_ + 0.75* tradeHistory.max_st_ )
	        		signal.ladderSell_ = false;


	        	// send to target with less shares
	        	if(venueControl_)
	        	{
					if(signalOK ==true)
					{
						if(route_ == "BAG2" || route_ == "NYX172" || route_ == "BAG8" )
						{
							if((dir==1 && inst->curPos_ >= 0) && (inst->limeBook_->subBook("NYOU").getSize(1,1) > inst->limeBook_->subBook("ARCA").getSize(1,1)
									))
								signalOK = false;
							else if((dir== -1 && inst->curPos_ <= 0) && (inst->limeBook_->subBook("NYOU").getSize(-1,1) > inst->limeBook_->subBook("ARCA").getSize(-1,1)
									))
								signalOK = false;
						}
						else if(route_ =="ARCE" || route_ =="ARCA")
						{
							int sharethr = 500;
							double ratiothr = 1.5;
							if(pending)
							{
								sharethr =200;
								ratiothr = 1.2;
							}
							if((dir==1 && inst->curPos_ >= 0) && (inst->limeBook_->subBook("NYOU").getSize(1,1) -sharethr < inst->limeBook_->subBook("ARCA").getSize(1,1)
									|| inst->limeBook_->subBook("NYOU").getSize(1,1) < ratiothr*inst->limeBook_->subBook("ARCA").getSize(1,1))
									)
								signalOK = false;
							else if((dir== -1 && inst->curPos_ <= 0) && (inst->limeBook_->subBook("NYOU").getSize(-1,1) - sharethr < inst->limeBook_->subBook("ARCA").getSize(-1,1)
									||inst->limeBook_->subBook("NYOU").getSize(-1,1) < ratiothr*inst->limeBook_->subBook("ARCA").getSize(-1,1))
									)
								signalOK = false;


							if(dir==1 && inst->curPos_ >= 0 && nyoubid> arcabid)
								signalOK = false;
							else if(dir== -1 && inst->curPos_ <= 0 && nyouask < arcaask)
								signalOK = false;
						}

					}
	        	}

	    	}

	        if (coeff.useSignal_ == 0)
	            signalOK = true;

	        if(coeff.useSignal_ == 3 && clock_ >= closeStartTime_ )
	        {
	        	if(signalOK == true)
	        	{
	        	if(dir==1 && inst->curPos_ >= 0 && signal.vwapSig_ - portVwapSig_ < - thetaVwap_)
	        		signalOK = true;
	        	else if(dir==1 && inst->curPos_ < 0 && signal.vwapSig_ - portVwapSig_ <  0.25*thetaVwap_)
	        		signalOK = true;
	        	else if(dir== -1 && inst->curPos_ <= 0 && signal.vwapSig_ - portVwapSig_ > thetaVwap_)
	        		signalOK = true;
	        	else if(dir== -1 && inst->curPos_ > 0 && signal.vwapSig_ - portVwapSig_ > -0.25*thetaVwap_)
	        		signalOK = true;
	        	else
	        		signalOK = false;
	        	}
	        	supportOK = true;
	        	emaGuardOK = true;
	        }

            if(dir==1 && signalOK && arcabid.valid() && nyoubid.valid() && arcabid != nyoubid)
            {
        		if(route_ == "BAG2" )
        			signalOK = false;
            	++alignSigFlips_;
            }
            if(dir== -1 && signalOK && arcaask.valid() && nyouask.valid() && arcaask != nyouask)
            {
        		if(route_ == "BAG2")
        			signalOK = false;
            	++alignSigFlips_;
            }

	    	if ((signalOK && supportOK && emaGuardOK) || aggressiveOut)
		    {
	            bool increasePos = (dir == 1 && inst->curPos_ > 0) || (dir == -1 && inst->curPos_ < 0);
	            // Do not increase position for now.
	            if (increasePos && !increasePosEnabled_)
	                continue;

	            double adjustedThreshold = imbThreshold_;
	    	    if (clock_ > closeStartTime_)
	    	        adjustedThreshold = 1.2 * imbThreshold_;
	    	    if (clock_ > closeEndTime_)
	    	        adjustedThreshold = 1.5 * imbThreshold_;

                if (dir == 1 && om_->getTotalImb() > adjustedThreshold )
                {
                    ++numImbLimitedOrders_;
                    continue;
                }
                if (dir == -1 && om_->getTotalImb() < -adjustedThreshold)
                {
                    ++numImbLimitedOrders_;
                    continue;
                }

                if (clock_ > closeEndTime_ && !getOut)
                {
                        continue;
                }

			    // Hao changed
			    pending = getPendingOrders(inst, dir, tradePx, true);
			    if (pending)
			        continue;

			    LimeBrokerage::Side tradeSide = side == 0 ? LimeBrokerage::sideBuy : LimeBrokerage::sideSellShort;

			    if ((dir == 1 && inst->maxPos_ + tradeSize > inst->posLimit_)
			    		|| (dir == -1 && inst->minPos_ - tradeSize < -inst->posLimit_))
			    {
			        ++numPosLimitedOrders_;
			    	continue;
			    }

			    if (useEquote_)
			    {
                    om_->sendParityOrder(this, inst->sym_, route_, Mode_Open, tradeSide,
                            tradePx.px4(), tradeSize, LimeBrokerage::TradingApi::OrderProperties::timeInForceDay, 0,
                            dir == 1 ? parityBuyStrategy_ : paritySellStrategy_);
			    }
			    else
			    {
			        LimeBrokerage::TradingApi::OrderProperties prop;
	                if (route_.find("ARCE") != std::string::npos || route_.find("ARCA") != std::string::npos)
	                    prop.setPostOnly(true);
                    om_->sendOrder(this, inst->sym_, route_, Mode_Open, tradeSide,
                            tradePx.px4(), tradeSize, LimeBrokerage::TradingApi::OrderProperties::timeInForceDay, 0, prop);
			    }

#ifdef ORDERBOOK
			    MTLOG("Sym:" << inst->sym_ << " Bid=" << bestBid.px4() << " Ask=" << bestAsk.px4() << "\n");
			    om_->orderBook().printBook(5, false);
#endif

#ifdef DEBUG
			    MTLOG("Sym:" << inst->sym_ << " Pos=" << inst->curPos_
			            << " Bid=" << bestBid.px4() << " Sz=" << bidSize << " Ask=" << bestAsk.px4() << " Sz=" << askSize
		                << " EMASTbid=" << signal.emaPxSt_[0] << " EMASTbidsz=" << signal.emaSzSt_[0]
		                << " EMASTask=" << signal.emaPxSt_[1] << " EMASTasksz=" << signal.emaSzSt_[1]
	                    << " EMALTbid=" << signal.emaPxLt_[0] << " EMALTbidsz=" << signal.emaSzLt_[0]
	                    << " EMALTask=" << signal.emaPxLt_[1] << " EMALTasksz=" << signal.emaSzLt_[1]
	                    << " BISI=" << signal.bisi_ << " DIR=" << signal.lastTickDir_ << " STBK=" << signal.staticBook_
	                    << " DYNBK=" << signal.dynaBook_ << " DYNBKLT=" << signal.dynaBookLt_ << " SIG=" << signal.signal_
	                    << " LastTr=" << signal.lastTrade_.px() << " LastSz=" << signal.lastSz_ << " AvgSz=" << signal.avgSz_
	                    << " AggressiveOut=" << aggressiveOut << " TotalIMB=" << om_->getTotalImb() << "\n");

			    if (rangeCheck_ && coeff.useSignal_ == 2)
			    {
                    TradeHistory& tradeHistory = tradeHistory_[inst];
                    MTLOG("RANGECHECK1: sym=" << inst->sym_ << " bid=" << bestBid.px() << " ask=" << bestAsk.px()
                            << " min=" << tradeHistory.min_ << " max=" << tradeHistory.max_
                            << " minst=" << tradeHistory.min_st_ << " maxst=" << tradeHistory.max_st_
                            << " minmt=" << tradeHistory.min_mt_ << " maxmt=" << tradeHistory.max_mt_
                            << " minlt=" << tradeHistory.min_lt_ << " maxlt=" << tradeHistory.max_lt_ << "\n");

                    MTLOG("RANGECHECK2: sym=" << inst->sym_ << " bid=" << bestBid.px() << " ask=" << bestAsk.px()
                            << " min=" << tradeHistory.min_ << " max=" << tradeHistory.max_
                            << " minst=" << tradeHistory.min_st_ << " maxst=" << tradeHistory.max_st_
                            << " minmt=" << tradeHistory.min_mt_ << " maxmt=" << tradeHistory.max_mt_
                            << " minlt=" << tradeHistory.min_lt_ << " maxlt=" << tradeHistory.max_lt_ << "\n");
			    }

#endif
		    }
		    else
		    {
		        int canceled = cancelPendingOrders(inst, dir, tradePx);
		    	if (canceled > 0)
		    	{
#ifdef DEBUG
		    		MTLOG("Sym:" << inst->sym_ << " Pos=" << inst->curPos_
		    		        << " Bid=" << bestBid.px4() << " Sz=" << bidSize << " Ask=" << bestAsk.px4() << " Sz=" << askSize
			                << " EMASTbid=" << signal.emaPxSt_[0] << " EMASTbidsz=" << signal.emaSzSt_[0]
			                << " EMASTask=" << signal.emaPxSt_[1] << " EMASTasksz=" << signal.emaSzSt_[1]
		                    << " EMALTbid=" << signal.emaPxLt_[0] << " EMALTbidsz=" << signal.emaSzLt_[0]
		                    << " EMALTask=" << signal.emaPxLt_[1] << " EMALTasksz=" << signal.emaSzLt_[1]
		                    << " BISI=" << signal.bisi_ << " DIR=" << signal.lastTickDir_ << " STBK=" << signal.staticBook_
		                    << " DYNBK=" << signal.dynaBook_ << " DYNBKLT=" << signal.dynaBookLt_ << " SIG=" << signal.signal_
		                    << " LastTr=" << signal.lastTrade_.px() << " LastSz=" << signal.lastSz_ << " AvgSz=" << signal.avgSz_
		                    << "\n");
#endif

			        std::string sideStr = side == 0 ? "BUY" : "SELL";
#ifdef DEBUG
			        MTLOG("Sym:" << inst->sym_ << " Canceling " << sideStr << " orders: cond1=" << signalOK
			        		<< " cond2=" << supportOK << " cond3=" << emaGuardOK << "\n");
#endif
			        if (!supportOK)
			        	supportCancel_ += canceled;
			        else if(!signalOK)
			        	signalCancel_ += canceled;
			        else if (!emaGuardOK)
			        	emaGuardCancel_ += canceled;
		    	}
		    }
	    }
#endif

	    //if (signal.bestPx_[0] != signal.prevBestPx_[0] || signal.bestPx_[1] != signal.prevBestPx_[1])
	    {
	        manageLadders(inst);
	    }
        for (int i = 0; i < 2; ++i)
        {
            signal.prevBestPx_[i] = signal.bestPx_[i];
            signal.prevBestSz_[i] = signal.bestSz_[i];
        }
	}

    return;
}

void Grape::computeStaticBook(Instrument* inst, Signal& signal)
{
	double prevStaticBook = signal.staticBook_;

	if (signal.bestPx_[0]<=0 || signal.bestPx_[1] <=0 || signal.bestSz_[0] <=0
			|| signal.bestSz_[1] <=0 || signal.bestPx_[0] >= signal.bestPx_[1])
	{
		MTLOG("Sym:" << inst->sym_ << "BookInvalid: bid:" << signal.bestPx_[0] << " sz:"
				<< signal.bestSz_[0] << " ask:" << signal.bestPx_[1] << " sz:" << signal.bestSz_[1] << "\n");
		signal.staticBook_ = 0;
		return;
	}

	const int MaxLevels = 10;

	double mid = (signal.bestPx_[0] + signal.bestPx_[1]) * 0.5;
	double rho = 800;
	double buySize = 0;
	double sellSize = 0;
	for (int i = 1; i <= MaxLevels; ++i)
	{
		double levelBidPx = inst->limeBook_->book().getPrice(1, i).px();
		int levelBidSize = inst->limeBook_->book().getSize(1, i);
		double levelAskPx = inst->limeBook_->book().getPrice(-1, i).px();
		int levelAskSize = inst->limeBook_->book().getSize(-1, i);

		if (levelBidSize ==0 || levelAskSize ==0)
			break;

		buySize += (double)(levelBidSize * exp(-rho * fabs(levelBidPx - mid) / mid));
		sellSize += (double)(levelAskSize * exp(-rho * fabs(levelAskPx - mid) / mid));
	}

	signal.staticBook_ = std::min(5.0, std::max(-5.0, log(buySize) - log(sellSize)));

	signal.dynaBook_ += signal.staticBook_ - prevStaticBook;
	signal.dynaBookLt_ += signal.staticBook_ - prevStaticBook;

//	inst->limeBook_->printBook(5, true);
//    MTLOG("Sym=" << inst->sym_ << " statbook=" << signal.staticBook_
//            << " dynabook=" << signal.dynaBook_ << " dynabookLT=" << signal.dynaBookLt_ << "\n");


}

void Grape::computeBISI(Instrument* inst, Signal& signal)
{
    double now = (double)nowMsec() / 1000;
    double sinceLastBI = std::max(0.001, 0.001 + now - signal.BITime_);
    double sinceLastSI = std::max(0.001, 0.001 + now - signal.SITime_);

    signal.bisi_ = std::min(3.0, std::max(-3.0, log(sinceLastSI) - log(sinceLastBI)));

}

bool Grape::onTrade(Instrument* inst, uint32_t timestamp, std::string const& quoteSource, Price4 const& px, uint32_t size,
            LimeBrokerage::QuoteSystemApi::Trade const& trade)
{
    BaseAlgo::onTrade(inst, timestamp, quoteSource, px, size, trade);
    if (quoteSource != "NYST" && quoteSource != "ARCT")
    	return true;

    if (!inst->opened_ && size > 0 && quoteSource == "NYST")
    {
        MTLOG("Sym:" << inst->sym_ << " MarketOpened\n");
        inst->opened_ = true;
    }

    Signal& signal = signals_[inst];
    //new add
    if(px == signal.lastTrade_)
    	signal.lastSz_ += size;
    else signal.lastSz_ = size;
    signal.avgSz_ = 0.99*signal.avgSz_ + 0.01*signal.lastSz_;

    signal.lastTrade_ = px;
    Price4 bestBid = inst->limeBook_->book().getPrice(1, 1);
    Price4 bestAsk = inst->limeBook_->book().getPrice(-1, 1);
    if (!bestBid.valid() || !bestAsk.valid() || bestBid >= bestAsk)
    	return true;
    if (px <= bestBid || (fabs(px.px() - signal.prevBestPx_[0]) < 0.001 && px< bestAsk))
    {
    	signal.SITime_ = (double)clock_ / 1000;
    	signal.lastTickDir_ = -0.5;
    }
    else if (px >= bestAsk || (fabs(px.px() - signal.prevBestPx_[1]) < 0.001 && px> bestBid))
    {
    	signal.BITime_ = (double)clock_ / 1000;
    	signal.lastTickDir_ = 0.5;
    }
    else
    	signal.lastTickDir_ = 0.0;

    Coefficients& coeff = getCoeffs(inst);
    if (rangeCheck_ && coeff.useSignal_ == 2)
    {
        int updown = 0;

        if(px.px() > tradeHistory_[inst].top())
            updown = 1;
        else if(px.px() < tradeHistory_[inst].top())
            updown = -1;
        else updown = 0;

        TradePrint print(timestamp, px, size, signal.lastTickDir_, updown, quoteSource);
        if(px.px4() >0 )
        {
            tradeHistory_[inst].insert(print, stLen_, mtLen_, ltLen_);
            tradeHistory_[inst].min_lt_ = tradeHistory_[inst].min(ltLen_);
            tradeHistory_[inst].min_mt_ = tradeHistory_[inst].min(mtLen_);
            tradeHistory_[inst].min_st_ = tradeHistory_[inst].min(stLen_);
            tradeHistory_[inst].max_lt_ = tradeHistory_[inst].max(ltLen_);
            tradeHistory_[inst].max_mt_ = tradeHistory_[inst].max(mtLen_);
            tradeHistory_[inst].max_st_ = tradeHistory_[inst].max(stLen_);

            if(tradeHistory_[inst].range_st_ <  0.01)
                tradeHistory_[inst].range_st_ = tradeHistory_[inst].range(stLen_);
            else
                tradeHistory_[inst].range_st_ = 0.99*tradeHistory_[inst].range_st_ + 0.01*tradeHistory_[inst].range(stLen_);

            if(tradeHistory_[inst].range_mt_ < 0.01)
                tradeHistory_[inst].range_mt_ = tradeHistory_[inst].range(mtLen_);
            else
                tradeHistory_[inst].range_mt_ = 0.99*tradeHistory_[inst].range_mt_ + 0.01*tradeHistory_[inst].range(mtLen_);

            if(tradeHistory_[inst].range_lt_ < 0.01)
                tradeHistory_[inst].range_lt_ = tradeHistory_[inst].range(ltLen_);
            else
                tradeHistory_[inst].range_lt_ = 0.99*tradeHistory_[inst].range_lt_ + 0.01*tradeHistory_[inst].range(ltLen_);
        }
    }
    if((int)timestamp > signalStartTime_ && px.px() > 0.01)
    {
        signal.totalVolume_ += (double)(size);
        signal.totalValue_ += (double)(size)*px.px();
        if(signal.totalVolume_ >10.0)
        {
        	signal.vwapPx_ = signal.totalValue_/signal.totalVolume_;
        	signal.vwapSig_ = (log(px.px()) - log(signal.vwapPx_))/(0.001);
        }
    }

    return true;
}

void Grape::decaySignals()
{
	if (lastDecay_ == 0)
	{
		lastDecay_ = clock_ / decayInterval_ * decayInterval_;
	}
	if (clock_ - lastDecay_ < decayInterval_)
		return;

	lastDecay_ = lastDecay_ + decayInterval_;

	Instruments *iu = Instruments::instance();
    Instruments::SymbolInstrumentMapIter it = iu->begin(), eIt = iu->end();
    for (; it != eIt; ++it)
    {
    	Signal& signal = signals_[it->second];
		signal.dynaBook_ = signal.dynaBook_ * 0.99;
		signal.dynaBookLt_ = signal.dynaBookLt_ * 0.995;

		signal.decayRetSt_ = signal.decayRetSt_ * 0.9;
		signal.decayRetMt_ = signal.decayRetMt_ * 0.95;
		signal.decayRetLt_ = signal.decayRetLt_ * 0.995;
    }
}

void Grape::computeSignal(Instrument* inst, Signal& signal)
{
    computeBISI(inst, signal);
    signal.signal_ = 0.00001 * signal.bisi_ + 0.00002 * signal.lastTickDir_ + 0.00004 * signal.staticBook_
            + 0.000122 * signal.dynaBook_ + 0.00008 * signal.dynaBookLt_;

#if 1
    //Instrument* instSPY = Instruments::instance()->getInstrument("SPY");
    //Instrument* instQQQ = Instruments::instance()->getInstrument("QQQ");
    signal.signal_ = dayCoeffs_[inst].statbook_coeff_ * signal.staticBook_
    		+ dayCoeffs_[inst].dynabookLt_coeff_ * signal.dynaBookLt_
    		+ dayCoeffs_[inst].lasttick_coeff_ * signal.lastTickDir_
    		//+ 0*dayCoeffs_[inst].spymt_coeff_ * signals_[instSPY].decayRetMt_
    		//+ 0*dayCoeffs_[inst].qqqmt_coeff_ * signals_[instQQQ].decayRetMt_
    		;
#endif
    //MTLOG("Sym:" << inst->sym_ << " BISI=" << signal.bisi_ << " DIR=" << signal.lastTickDir_ << " STBK=" << signal.staticBook_
    //        << " DYNBK=" << signal.dynaBook_ << " DYNBKLT=" << signal.dynaBookLt_ << " SIG=" << signal.signal_ << "\n");
}

void Grape::checkPendingOrders(Instrument* inst, int dir, Price4 bestPx, std::vector<AlgoOrder*>& toRemove,
        std::vector<Price4>& toAdd)
{
    Coefficients& coeff = getCoeffs(inst);
    int numLadders = coeff.numLadder_;

    int cancelPending = 0;
    std::vector<bool> levelHasOrder(numLadders, false);
    for (Instrument::AlgoOrderMapIter iter = inst->openOrders_.begin();
            iter != inst->openOrders_.end(); ++iter) {
        if (OrderManager::sideToDir(iter->second->side_) != dir)
            continue;

        AlgoOrder* order = iter->second;
        if (order->state_ == Order::PENDING_CANCEL)
            ++cancelPending;

        int level = -dir * ( (int)order->px_.px4() - (int)bestPx.px4()) / 100;
        if (level < 0)
        	continue;
        if (level < numLadders)
        {
            Coefficients& coeff = getCoeffs(inst);
            if (order->szPending_ > coeff.tradeSize_ || inst->reduceOnly_ || (dir==1 && !signals_[inst].ladderBuy_) || (dir==-1 && !signals_[inst].ladderSell_))
            {
                toRemove.push_back(order);
            }
            else
            {
                if (levelHasOrder[level])
                {
                    MTLOG("#### WARNING #### Sym:" << inst->sym_ << " multiple orders on price level " << order->px_);
                }
                else
                {
                    levelHasOrder[level] = true;
                }
            }
        }
        else
        {
            toRemove.push_back(order);
        }
    }

    if (cancelPending > 0)
        return;

    for (uint32_t i = 0; i < levelHasOrder.size(); ++i)
    {
        if (!levelHasOrder[i] && ((dir==1 && signals_[inst].ladderBuy_) || (dir==-1 && signals_[inst].ladderSell_)))
        {
            Price4 px = Price4(bestPx.px4() + (-dir) * i * 100);
            toAdd.push_back(px);
        }
    }
}

void Grape::manageLadders(Instrument* inst)
{
    Price4 bestBid = inst->limeBook_->book().getPrice(1, 1);
    Price4 bestAsk = inst->limeBook_->book().getPrice(-1, 1);

    //MTLOG("Sym:" << inst->sym_ << " Manage Ladder bid=" << bestBid.px4() << " ask=" << bestAsk.px4() << "\n");

    for (int side = 0; side < 2; ++side)
    {
        std::vector<AlgoOrder*> toRemove;
        std::vector<Price4> toAdd;

        int dir = 1 - side * 2;
        Price4 ladderPx;
        if (side == 0)
            ladderPx = Price4(bestBid.px4() - 100);
        else
            ladderPx = Price4(bestAsk.px4() + 100);
        checkPendingOrders(inst, dir, ladderPx, toRemove, toAdd);
        if (toRemove.size() > 0)
        {
        	std::stringstream sstream;
            for (uint32_t i = 0; i < toRemove.size(); ++i)
            {
            	sstream << toRemove[i]->orderId_ << " ";
            }
            //MTLOG("ToRemove: " << sstream.str() << "\n");
        }
        if (toAdd.size() > 0)
        {
        	std::stringstream sstream;
			for (uint32_t i = 0; i < toAdd.size(); ++i)
			{
				sstream << toAdd[i].px4() << " ";
			}
			//MTLOG("ToAdd: " << sstream.str() << "\n");
        }
        if (!toRemove.empty())
        {
            for (uint32_t i = 0; i < toRemove.size(); ++i)
            {
            	if (Order::isCancelable(toRemove[i]->state_))
            	{
            		MTLOG("ManageLadder cancel orderId=" << toRemove[i]->orderId_ << "\n");
                    om_->sendCancel(toRemove[i]->orderId_);
            	}
            	else
            	{
            		//MTLOG("ManageLadder orderId=" << toRemove[i]->orderId_ << " not removable\n");
            	}
            }
            continue;
        }

        // Do not put ladders for reduce only symbols.
        if (inst->reduceOnly_)
            continue;

        LimeBrokerage::Side tradeSide;
        if (side == 0)
            tradeSide = LimeBrokerage::sideBuy;
        else
            tradeSide = LimeBrokerage::sideSellShort;

        const Coefficients& coeff = getCoeffs(inst);
        for (uint32_t i = 0; i < toAdd.size(); ++i)
        {
            if ((dir == 1 && inst->maxPos_ + coeff.tradeSize_ > std::min(inst->posLimit_, coeff.tradeSize_ * (coeff.numLadder_+1)))
                    || (dir == -1 && inst->minPos_ - coeff.tradeSize_ < -std::min(inst->posLimit_, coeff.tradeSize_ * (coeff.numLadder_+1))))
            {
                ++numPosLimitedOrders_;
                continue;
            }

            if (useEquote_)
            {
                om_->sendParityOrder(this, inst->sym_, route_, Mode_Open, tradeSide,
                        toAdd[i].px4(), coeff.tradeSize_, LimeBrokerage::TradingApi::OrderProperties::timeInForceDay, 0,
                        dir == 1 ? parityBuyStrategy_ : paritySellStrategy_);
            }
            else
            {
                om_->sendOrder(this, inst->sym_, route_, Mode_Open, tradeSide,
                        toAdd[i].px4(), coeff.tradeSize_, LimeBrokerage::TradingApi::OrderProperties::timeInForceDay, 0);
            }
        }
    }
}

void Grape::onOrderAck(AlgoOrder* order)
{
	BaseAlgo::onOrderAck(order);
#ifdef ORDERBOOK
	om_->orderBook().printBook(5, true);
    Instrument* inst = Instruments::instance()->getInstrument(
            order->symbol_);
	SimTrader::get()->getSimBook(inst).printBook(5, true);
#endif
}

void Grape::onOrderCancel(AlgoOrder* order)
{
	BaseAlgo::onOrderCancel(order);

#ifdef ORDERBOOK
	om_->orderBook().printBook(5, true);
    Instrument* inst = Instruments::instance()->getInstrument(
            order->symbol_);
    Price4 bestBid = inst->limeBook_->book().getPrice(1, 1);
    Price4 bestAsk = inst->limeBook_->book().getPrice(-1, 1);
    Price4 simBid = SimTrader::get()->getSimBook(inst).getPrice(1, 1);
    Price4 simAsk = SimTrader::get()->getSimBook(inst).getPrice(-1, 1);
	SimTrader::get()->getSimBook(inst).printBook(5, true);
    if ((simBid.valid() && bestAsk.valid() && simBid > bestAsk)
    		|| (simAsk.valid() && bestBid.valid() && simAsk < bestBid))
    	printf("Debug\n");

#endif
}

void Grape::onOrderReject(AlgoOrder* order, RejectReason reason)
{
	BaseAlgo::onOrderReject(order, reason);

	Instrument* inst = Instruments::instance()->getInstrument(
            order->symbol_);
	if (!inst)
	    return;
	if (clock_ > closeStartTime_ && reason == RejNoMatchingOrder)
	{
	    Coefficients* coeff = &closeCoeffs_[inst];
	    coeff->tradeSize_ = std::max(50, coeff->tradeSize_ / 2);
        MTLOG("symbol=" << inst->sym_ << " No Parent Order Reject. Reducing TradeSize to " << coeff->tradeSize_ << "\n");
	}

#ifdef ORDERBOOK
	om_->orderBook().printBook(5, true);
#endif
}

void Grape::onOrderFill(AlgoOrder* order, LimeBrokerage::Listener::FillInfo const& fillinfo)
{
	BaseAlgo::onOrderFill(order, fillinfo);
    Instrument* inst = Instruments::instance()->getInstrument(
            order->symbol_);
//    inst->limeBook_->printBook(5, true);

    Price4 bestBid = inst->limeBook_->book().getPrice(1, 1);
    Price4 bestAsk = inst->limeBook_->book().getPrice(-1, 1);
    int bidSize = inst->limeBook_->book().getSize(1, 1);
    int askSize = inst->limeBook_->book().getSize(-1, 1);

    Signal& signal = signals_[inst];
    MTLOG("Sym:" << inst->sym_ << " Pos=" << inst->curPos_
            << " Bid=" << bestBid.px4() << " Sz=" << bidSize << " Ask=" << bestAsk.px4() << " Sz=" << askSize
            << " EMASTbid=" << signal.emaPxSt_[0] << " EMASTbidsz=" << signal.emaSzSt_[0]
            << " EMASTask=" << signal.emaPxSt_[1] << " EMASTasksz=" << signal.emaSzSt_[1]
            << " EMALTbid=" << signal.emaPxLt_[0] << " EMALTbidsz=" << signal.emaSzLt_[0]
            << " EMALTask=" << signal.emaPxLt_[1] << " EMALTasksz=" << signal.emaSzLt_[1]
            << " BISI=" << signal.bisi_ << " DIR=" << signal.lastTickDir_ << " STBK=" << signal.staticBook_
            << " DYNBK=" << signal.dynaBook_ << " DYNBKLT=" << signal.dynaBookLt_ << " SIG=" << signal.signal_
            << " TotalIMB=" << om_->getTotalImb() << "\n");

    checkStopLoss(inst);

#ifdef ORDERBOOK
	om_->orderBook().printBook(5, true);
    Instrument* inst = Instruments::instance()->getInstrument(
            order->symbol_);
    Price4 bestBid = inst->limeBook_->book().getPrice(1, 1);
    Price4 bestAsk = inst->limeBook_->book().getPrice(-1, 1);
    Price4 simBid = SimTrader::get()->getSimBook(inst).getPrice(1, 1);
    Price4 simAsk = SimTrader::get()->getSimBook(inst).getPrice(-1, 1);
	SimTrader::get()->getSimBook(inst).printBook(5, true);
    if ((simBid.valid() && bestAsk.valid() && simBid > bestAsk)
    		|| (simAsk.valid() && bestBid.valid() && simAsk < bestBid))
    	printf("Debug\n");
#endif
}

void Grape::cancelBadClosingOrders(Instrument* inst)
{
    char const *sym = inst->sym_;
    for (Instrument::AlgoOrderMapIter iter = inst->openOrders_.begin();
            iter != inst->openOrders_.end(); ++iter) {

        if (!Order::isOutStanding(iter->second->state_))
        	continue;
        int dir = OrderManager::sideToDir(iter->second->side_);
        Price4 goodPx;
        if (inst->curPos_ > 0)
            goodPx = inst->limeBook_->book().getPrice(-1, 1);
        else
            goodPx = inst->limeBook_->book().getPrice(1, 1);

        if (((inst->curPos_ > 0 && dir < 0) || (inst->curPos_ < 0 && dir > 0))
        		&& (iter->second->szPending_ == abs(inst->curPos_))
        		&& (iter->second->px_ == goodPx))
        {
        	MTLOG("orderId=" << iter->first << " Good closing order\n");
        	continue;
        }
		if (iter->second->state_ == Order::PENDING_CANCEL  || iter->second->state_ < Order::ACKED)
		{
			//MTLOG("Sym=[" << sym << " orderId=" << iter->first << " already canceling\n");
		}
		else
		{
			int ret = om_->sendCancel(iter->first);
			if (!ret)
			{
				if (om_->getLiveTrading())
				{
					MTLOG("Sym=" << sym << " SendCxl for orderId="
							<< iter->first << "\n");
				}
				else
				{
					MTLOG("EventTm=" << msec2hrTm(clock_) << " sym=" << sym
							<< " SendCxl for orderId=" << iter->first << "\n");
				}
			}
			else
			{
				MTLOG("OrdMgr: sym=[" << sym << "] failed to cancel orderId=["
						<< iter->first << "] ret=[" << ret << "]\n");
			}
		}
    }
}

void Grape::cancelBadOpenOrders(Instrument* inst)
{
    char const *sym = inst->sym_;
    for (Instrument::AlgoOrderMapIter iter = inst->openOrders_.begin();
            iter != inst->openOrders_.end(); ++iter) {

        if (!Order::isOutStanding(iter->second->state_))
            continue;
        int dir = OrderManager::sideToDir(iter->second->side_);
        if (((inst->curPos_ > 0 && dir < 0) || (inst->curPos_ < 0 && dir > 0)))
        {
            MTLOG("orderId=" << iter->first << "Closing order\n");
            continue;
        }

        Coefficients& coeff = getCoeffs(inst);
        if (iter->second->state_ == Order::PENDING_CANCEL  || iter->second->state_ < Order::ACKED)
        {
            //MTLOG("Sym=[" << sym << " orderId=" << iter->first << " already canceling\n");
        }
        else if (iter->second->sz_ > coeff.tradeSize_)
        {
            int ret = om_->sendCancel(iter->first);
            if (!ret)
            {
                if (om_->getLiveTrading())
                {
                    MTLOG("Sym=" << sym << " SendCxl for orderId="
                            << iter->first << "\n");
                }
                else
                {
                    MTLOG("EventTm=" << msec2hrTm(clock_) << " sym=" << sym
                            << " SendCxl for orderId=" << iter->first << "\n");
                }
            }
            else
            {
                MTLOG("OrdMgr: sym=[" << sym << "] failed to cancel orderId=["
                        << iter->first << "] ret=[" << ret << "]\n");
            }
        }
    }
}

bool Grape::handleAlgoCommand(Poco::StringTokenizer::Iterator tok,
        Poco::StringTokenizer::Iterator end,
        std::iostream& stream)
{
	if (tok == end)
	{
		stream << "Unable to process command\n";
		return false;
	}

	const std::string command = *tok++;
	if (command == "HELP")
	{
		stream << "Help -- list available commands\n";
		stream << "ReloadCoeff -- reload algo coefficients\n";
		stream << "GetDayCoeff symbol\n";
		stream << "SetDayCoeff symbol params\n";
        stream << "GetEODCoeff symbol\n";
        stream << "SetEODCoeff symbol params\n";
        stream << "GetSymLossThr\n";
        stream << "SetSymLossThr thr\n";
        stream << "GetOverallLossThr\n";
        stream << "SetOverallLossThr thr\n";
        stream << "SetRangeCheck\n";
        stream << "UnsetRangeCheck\n";
        stream << "SetIncreasePos\n";
        stream << "UnsetIncreasePos\n";
        stream << "SetTickCancel\n";
        stream << "UnsetTickCancel\n";
        stream << "SetRevControl\n";
        stream << "UnsetRevControl\n";
        stream << "SetVenueControl\n";
        stream << "UnsetVenueControl\n";
		return true;
	}
	else if (command == "RELOADCOEFF")
	{
	    Poco::AutoPtr<Poco::Util::IniFileConfiguration> pConf = new Poco::Util::IniFileConfiguration(config_);
	    std::string coeffFile;
	    const std::string prefix = "Grape";
	    std::string key;
	    key = prefix + ".DayCoeffFile";
	    if (pConf->has(key))
	    {
	        coeffFile = pConf->getString(key);
	        loadCoeffs(dayCoeffs_, coeffFile);
	        stream << "Successfully reloaded Day coeff\n";
	    }
	    else
	    {
	        stream << "Missing day coeff file\n";
	        return false;
	    }
	    key = prefix + ".CloseCoeffFile";
	    if (pConf->has(key))
	    {
	        coeffFile = pConf->getString(key);
	        loadCoeffs(closeCoeffs_, coeffFile);
	        stream << "Successfully reloaded EOD coeff\n";
	    }
	    else
	    {
	        stream << "Missing close coeff file\n";
	        return false;
	    }
		return true;
	}
	else if (command == "GETDAYCOEFF" || command == "GETEODCOEFF")
	{
        if (tok == end)
        {
            stream << "Missing symbol argument!\n";
            return true;
        }
        Instrument *inst = Instruments::instance()->getInstrument(*tok);
        if (!inst)
        {
            stream << "Unknown symbol!\n";
            return true;
        }

        Coefficients coeff;
        if (command == "GETDAYCOEFF")
        {
            coeff = dayCoeffs_[inst];
        }
        else
        {
            coeff = closeCoeffs_[inst];
        }

        stream << "Symbol=" << *tok << " Coeff=" << coeff.toString() << "\n";
        return true;
	}
    else if (command == "SETDAYCOEFF" || command == "SETEODCOEFF")
    {
        if (end - tok != 8)
        {
            stream << "Expecting 8 parameters for this command, getting " <<  end - tok << ".\n";
            return true;
        }

        std::string symbol = *tok;
        Instrument *inst = Instruments::instance()->getInstrument(symbol);
        if (!inst)
        {
            stream << "Unknown symbol!\n";
            return true;
        }

        Coefficients* coeff;
        if (command == "SETDAYCOEFF")
        {
            coeff = &dayCoeffs_[inst];
        }
        else
        {
            coeff = &closeCoeffs_[inst];
        }

        ++tok;

        try
        {
            coeff->tradeSize_ = Poco::NumberParser::parse(*tok++);
            coeff->maxShares_ = Poco::NumberParser::parse(*tok++);
            coeff->minSupportSz_ = Poco::NumberParser::parse(*tok++);
            coeff->sizeThresh_ = Poco::NumberParser::parseFloat(*tok++);
            coeff->useSignal_ = Poco::NumberParser::parse(*tok++);
            coeff->aggressiveOut_ = Poco::NumberParser::parse(*tok++);
            coeff->numLadder_ = Poco::NumberParser::parse(*tok++);
        }
        catch (Poco::SyntaxException&)
        {
            stream << "Error parsing parameters\n";
            return false;
        }

        stream << "Symbol=" << symbol << " Coeff=" << coeff->toString() << "\n";
        return true;
    }
    else if (command == "GETSYMLOSSTHR")
    {
        stream << "SymStopLoss is " << symStopLoss_ << "\n";
        return true;
    }
    else if (command == "SETSYMLOSSTHR")
    {
        if (tok == end)
        {
            stream << "Missing threshold!\n";
            return true;
        }
        int thr = 0;
        try
        {
            thr = Poco::NumberParser::parse(*tok);
        }
        catch (Poco::SyntaxException&)
        {
            thr = 0;
        }
        if ( thr <= 0)
        {
            stream << "Bad threshold input: " << thr << "\n";
            return false;
        }
        int prev = symStopLoss_;
        symStopLoss_ = thr;

        stream << "SymStopLoss limit prev: " << prev << " new:" << symStopLoss_ << "\n";
        return true;
    }
    else if (command == "GETOVERALLLOSSTHR")
    {
        stream << "OverallStopLoss is " << overallStopLoss_ << "\n";
        return true;
    }
    else if (command == "SETOVERALLLOSSTHR")
    {
        if (tok == end)
        {
            stream << "Missing threshold!\n";
            return true;
        }
        int thr = 0;
        try
        {
            thr = Poco::NumberParser::parse(*tok);
        }
        catch (Poco::SyntaxException&)
        {
            thr = 0;
        }
        if ( thr <= 0)
        {
            stream << "Bad threshold input: " << thr << "\n";
            return false;
        }
        int prev = overallStopLoss_;
        overallStopLoss_ = thr;

        stream << "OverallStopLoss limit prev: " << prev << " new:" << overallStopLoss_ << "\n";
        return true;
    }
    else if (command == "SETRANGECHECK")
    {
        rangeCheck_ = true;
        stream << "Setting RangeCheck to true\n";
        return true;
    }
    else if (command == "UNSETRANGECHECK")
    {
        rangeCheck_ = false;
        stream << "Setting RangeCheck to false\n";
        return true;
    }
    else if (command == "SETREVCONTROL")
    {
        revControl_ = true;
        stream << "Setting RevControl to true\n";
        return true;
    }
    else if (command == "UNSETREVCONTROL")
    {
        revControl_ = false;
        stream << "Setting RevControl to false\n";
        return true;
    }
    else if (command == "SETVENUECONTROL")
    {
        venueControl_ = true;
        stream << "Setting VenueControl to true\n";
        return true;
    }
    else if (command == "UNSETVENUECONTROL")
    {
        venueControl_ = false;
        stream << "Setting VenueControl to false\n";
        return true;
    }

    else if (command == "SETINCREASEPOS")
    {
        increasePosEnabled_ = true;
        stream << "Setting IncreasePos to true\n";
        return true;
    }
    else if (command == "UNSETINCREASEPOS")
    {
        increasePosEnabled_ = false;
        stream << "Setting IncreasePos to false\n";
        return true;
    }
    else if (command == "SETTICKCANCEL")
    {
        tickCancelEnabled_ = true;
        stream << "Setting TickCancel to true\n";
        return true;
    }
    else if (command == "UNSETTICKCANCEL")
    {
        tickCancelEnabled_ = false;
        stream << "Setting TickCancel to false\n";
        return true;
    }

	return false;
}

void Grape::dumpStrategyStat()
{
    BaseAlgo::dumpStrategyStat();
    MTLOG("SignalCxl=" << signalCancel_ << " SupportCxl=" << supportCancel_ << " EMACxl=" << emaGuardCancel_
            << " BookCross=" << numBookCrosses_ << " PosLimited=" << numPosLimitedOrders_ << " ImbLimited=" << numImbLimitedOrders_
            << " SigFlips=" << tickSigFlips_ << " SupportFlips=" << tickSupportFlips_ << " EMAFlips=" << tickEMAFlips_
            << " Range1SigFlips=" << range1SigFlips_ << " Range2SigFlips=" << range2SigFlips_ << " AlignSigFlips=" << alignSigFlips_ << "\n");
}


