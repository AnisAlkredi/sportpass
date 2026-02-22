import AppInterfacesSection from "./components/AppInterfacesSection";
import BrochureFlowSection from "./components/BrochureFlowSection";
import FinalCtaSection from "./components/FinalCtaSection";
import HeaderNav from "./components/HeaderNav";
import OwnerControlSection from "./components/OwnerControlSection";
import PageFooter from "./components/PageFooter";
import PartnerBenefits from "./components/PartnerBenefits";
import PartnerHero from "./components/PartnerHero";
import PartnerHowItWorks from "./components/PartnerHowItWorks";
import PilotTrustSection from "./components/PilotTrustSection";
import UserSection from "./components/UserSection";

export default function HomePage() {
  return (
    <>
      <div className="orb orb-a" />
      <div className="orb orb-b" />
      <div className="orb orb-c" />

      <HeaderNav />

      <main>
        <PartnerHero />
        <PartnerBenefits />
        <PartnerHowItWorks />
        <OwnerControlSection />
        <BrochureFlowSection />
        <AppInterfacesSection />
        <PilotTrustSection />
        <UserSection />
        <FinalCtaSection />
      </main>

      <PageFooter />
    </>
  );
}
