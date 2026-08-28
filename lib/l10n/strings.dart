enum Language { en, hi }

class NavLabels {
  final String home, catalog, growth, support;
  const NavLabels({
    required this.home,
    required this.catalog,
    required this.growth,
    required this.support,
  });
}

class DashboardStrings {
  // Home
  final String addTitle, addSubtext, addButtonLabel;
  final String overview, salesLabel, productsLabel;
  final String recentOrders, orderStatus, whatsapp;

  // Catalog
  final String catalogTitle, addNewProduct;
  final String editVoiceInfo, completeListing;
  final String statusLive, statusDraft;

  // Growth
  final String growthTitle, darkModeLabel;
  final String revenueLabel, trendLabel;
  final String chartTitle, peakLabel;
  final String totalOrdersLabel, avgOrderLabel;

  // Help / Support
  final String supportTitle, supportTitleAlt;
  final String askTitle, askSubtext, askButtonLabel;
  final String whatsappHelpTitle, whatsappHelpText;
  final String tutorialTitle, tutorialText, playLabel;
  final String callTitle, callNumber;

  // Shipped modal
  final String shippedTitle, shippedPill;
  final String buyerLabel, courierLabel;
  final String shareTracking, done;

  // New order toast
  final String toastTitle, toastOrder, accept;

  final NavLabels nav;

  const DashboardStrings({
    required this.addTitle, required this.addSubtext, required this.addButtonLabel,
    required this.overview, required this.salesLabel, required this.productsLabel,
    required this.recentOrders, required this.orderStatus, required this.whatsapp,
    required this.catalogTitle, required this.addNewProduct,
    required this.editVoiceInfo, required this.completeListing,
    required this.statusLive, required this.statusDraft,
    required this.growthTitle, required this.darkModeLabel,
    required this.revenueLabel, required this.trendLabel,
    required this.chartTitle, required this.peakLabel,
    required this.totalOrdersLabel, required this.avgOrderLabel,
    required this.supportTitle, required this.supportTitleAlt,
    required this.askTitle, required this.askSubtext, required this.askButtonLabel,
    required this.whatsappHelpTitle, required this.whatsappHelpText,
    required this.tutorialTitle, required this.tutorialText, required this.playLabel,
    required this.callTitle, required this.callNumber,
    required this.shippedTitle, required this.shippedPill,
    required this.buyerLabel, required this.courierLabel,
    required this.shareTracking, required this.done,
    required this.toastTitle, required this.toastOrder, required this.accept,
    required this.nav,
  });
}

const kStrings = <Language, DashboardStrings>{
  Language.en: DashboardStrings(
    addTitle: 'Snap & Speak to Add Product',
    addSubtext: 'No typing required. AI will do the rest.',
    addButtonLabel: 'Add a product using camera and voice',
    overview: 'Business Overview',
    salesLabel: "Today's Sales",
    productsLabel: 'Active Products',
    recentOrders: 'Recent Orders',
    orderStatus: 'New order',
    whatsapp: 'Manage on WhatsApp',
    catalogTitle: 'My Products',
    addNewProduct: 'Add New Product',
    editVoiceInfo: 'Edit Voice Info',
    completeListing: 'Complete Listing',
    statusLive: 'Live on ONDC',
    statusDraft: 'Draft',
    growthTitle: 'Business Growth',
    darkModeLabel: 'Dark mode',
    revenueLabel: 'Earned this month',
    trendLabel: 'this week',
    chartTitle: 'Weekly Earnings',
    peakLabel: 'Best day',
    totalOrdersLabel: 'Total Orders',
    avgOrderLabel: 'Avg. Order Value',
    supportTitle: 'Need Help?',
    supportTitleAlt: 'सहायता',
    askTitle: 'Tap to Ask Anything in Your Language',
    askSubtext: 'No typing needed. Speak your query.',
    askButtonLabel: 'Tap to ask your question by voice',
    whatsappHelpTitle: 'Chat on WhatsApp Support',
    whatsappHelpText: 'Get 24/7 instant help on WhatsApp',
    tutorialTitle: 'Audio Tutorial: How to sell on ONDC',
    tutorialText: '4 min listen · Hindi & English',
    playLabel: 'Play audio tutorial',
    callTitle: 'Call Artisan Support Helpline',
    callNumber: '1800-HANDORA',
    shippedTitle: 'Order #HD-8921 Shipped!',
    shippedPill: 'Shipped',
    buyerLabel: 'Buyer',
    courierLabel: 'Track with',
    shareTracking: 'Share Tracking on WhatsApp',
    done: 'Done',
    toastTitle: 'New Order Received!',
    toastOrder: '₹1,200 · Handwoven Scarf',
    accept: 'Accept',
    nav: NavLabels(home: 'Home', catalog: 'Catalog', growth: 'Growth', support: 'Help'),
  ),

  Language.hi: DashboardStrings(
    addTitle: 'फ़ोटो लें और बोलें',
    addSubtext: 'टाइप करने की ज़रूरत नहीं। बाकी काम AI करेगा।',
    addButtonLabel: 'कैमरा और आवाज़ से उत्पाद जोड़ें',
    overview: 'व्यापार का हाल',
    salesLabel: 'आज की बिक्री',
    productsLabel: 'चालू उत्पाद',
    recentOrders: 'नए ऑर्डर',
    orderStatus: 'नया ऑर्डर',
    whatsapp: 'WhatsApp पर देखें',
    catalogTitle: 'मेरे उत्पाद',
    addNewProduct: 'नया उत्पाद जोड़ें',
    editVoiceInfo: 'बोलकर बदलें',
    completeListing: 'लिस्टिंग पूरी करें',
    statusLive: 'ONDC पर लाइव',
    statusDraft: 'अधूरा',
    growthTitle: 'कमाई का हाल',
    darkModeLabel: 'डार्क मोड',
    revenueLabel: 'इस महीने की कमाई',
    trendLabel: 'इस हफ़्ते',
    chartTitle: 'हफ़्ते की कमाई',
    peakLabel: 'सबसे अच्छा दिन',
    totalOrdersLabel: 'कुल ऑर्डर',
    avgOrderLabel: 'औसत ऑर्डर',
    supportTitle: 'सहायता',
    supportTitleAlt: 'Need Help?',
    askTitle: 'अपनी भाषा में कुछ भी पूछें',
    askSubtext: 'टाइप करने की ज़रूरत नहीं। बस बोलिए।',
    askButtonLabel: 'बोलकर सवाल पूछने के लिए दबाएँ',
    whatsappHelpTitle: 'WhatsApp पर बात करें',
    whatsappHelpText: '24/7 तुरंत मदद पाएँ',
    tutorialTitle: 'ऑडियो गाइड: ONDC पर कैसे बेचें',
    tutorialText: '4 मिनट · हिंदी और अंग्रेज़ी',
    playLabel: 'ऑडियो गाइड सुनें',
    callTitle: 'कारीगर हेल्पलाइन पर कॉल करें',
    callNumber: '1800-HANDORA',
    shippedTitle: 'ऑर्डर #HD-8921 भेज दिया!',
    shippedPill: 'भेजा गया',
    buyerLabel: 'ख़रीदार',
    courierLabel: 'ट्रैक करें',
    shareTracking: 'WhatsApp पर ट्रैकिंग भेजें',
    done: 'ठीक है',
    toastTitle: 'नया ऑर्डर आया!',
    toastOrder: '₹1,200 · हाथ से बुना दुपट्टा',
    accept: 'स्वीकारें',
    nav: NavLabels(home: 'होम', catalog: 'सामान', growth: 'कमाई', support: 'मदद'),
  ),
};
