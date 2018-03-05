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



