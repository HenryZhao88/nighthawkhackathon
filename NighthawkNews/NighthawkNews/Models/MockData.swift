import Foundation

enum MockData {
    private static func ago(hours h: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: -h, to: Date()) ?? Date()
    }

    private static func stableID(_ sequence: UInt8) -> UUID {
        UUID(uuid: (
            0x6e, 0x65, 0x77, 0x73,
            0x68, 0x61,
            0x77, 0x6b,
            0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, sequence
        ))
    }

    private static func demoID(_ sequence: UInt8) -> UUID {
        UUID(uuid: (
            0x64, 0x65, 0x6d, 0x6f,
            0x6e, 0x68,
            0x77, 0x6b,
            0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, sequence
        ))
    }

    /// Curated dataset for App Store screenshots and demo recordings.
    ///
    /// Every article uses fictional people, fictional companies, and invented
    /// research bodies. There are deliberately no references to real
    /// celebrities, athletes, sports teams, leagues, studios, or branded
    /// products — App Store guideline 4.1(a) prohibits leveraging third-party
    /// names/likenesses in marketing materials without authorization, and
    /// screenshots taken from this dataset are guaranteed safe.
    static let demoArticles: [Article] = [
        Article(
            id: demoID(1),
            title: "Coastal Cities Pilot Floating Solar Arrays to Power Desalination Plants",
            excerpt: "A consortium of four municipalities is testing modular floating solar to offset the energy cost of fresh-water production. Early data show a 31% drop in grid draw at the largest pilot site.",
            body: """
Four coastal municipalities have begun a joint two-year trial of modular floating solar arrays anchored just offshore from their desalination facilities. The pilot, organized by a regional water authority, aims to determine whether the daytime energy demands of reverse-osmosis filtration can be met directly by co-located renewable generation rather than drawn from the broader grid.

Engineers at the largest of the four sites reported a 31% reduction in grid draw during peak production hours, with intermittent periods of net export back to the local utility. The arrays are designed to withstand twelve-meter swells and use a flexible mooring system that allows them to ride storm surges without structural damage.

Independent reviewers from the regional energy lab noted that floating solar siting offers two co-benefits beyond generation: the arrays reduce evaporation in the intake basins and lower seawater surface temperatures slightly, both of which marginally improve the efficiency of the downstream filtration units.

The next phase of the trial will introduce small-scale battery storage to cover the early-morning hour before solar production ramps up. If results hold across the planned summer testing window, the consortium intends to publish a deployment template that other coastal municipalities can adapt for their own facilities.
""",
            imageURL: "https://picsum.photos/seed/demo1/600/400",
            source: "Local Energy Review",
            category: "Science",
            publishedAt: ago(hours: 2),
            bias: nil
        ),

        Article(
            id: demoID(2),
            title: "Rural Library Network Reports Record Year for Adult Literacy Programs",
            excerpt: "Volunteer-led tutoring sessions reached more than 14,000 adult learners across the county network last year. Coordinators credit a new evening schedule that better fits working families.",
            body: """
The county library network released its annual learning programs report this week, showing that volunteer-led adult literacy tutoring served 14,200 learners over the past year — a 38% increase compared to the prior period. Coordinators attribute the growth largely to a schedule shift that moved most sessions to weekday evenings and Saturday mornings, hours that better match the availability of working adults.

The program pairs trained volunteer tutors with adult learners on a one-to-one basis, working through reading, writing, and basic numeracy at the learner's pace. About 60% of participants are working toward a high-school equivalency credential; the remainder are pursuing improved reading for everyday tasks such as helping children with homework or navigating workplace documents.

The network's director said retention has been the most significant change. Learners who attend their first three sessions are now 72% likely to remain in the program for at least six months, up from 51% two years ago. She credited a redesigned onboarding flow that emphasizes early goal-setting with each learner.

Funding for the program comes from a mix of state library grants, private donations, and a small-business sponsorship pilot in which local employers cover materials costs in exchange for a community recognition listing in the library's newsletter. The network is now exploring expanding the model to a neighboring county that has expressed interest.
""",
            imageURL: "https://picsum.photos/seed/demo2/600/400",
            source: "County Civic Reporter",
            category: "Politics",
            publishedAt: ago(hours: 4),
            bias: nil
        ),

        Article(
            id: demoID(3),
            title: "Independent Researchers Develop Open-Source Tool for Water-Quality Monitoring",
            excerpt: "A volunteer engineering collective has released a low-cost sensor kit that streams real-time pH, turbidity, and dissolved-oxygen readings to a public dashboard.",
            body: """
A volunteer engineering collective announced this week the public release of an open-source water-quality monitoring kit that pairs a low-cost microcontroller with a trio of off-the-shelf sensors to produce real-time readings of pH, turbidity, and dissolved oxygen. The kit costs under $90 in parts and uploads readings every fifteen minutes to a public dashboard that anyone can browse.

The team's stated goal is to give community groups and small watershed organizations the ability to maintain their own continuous monitoring stations rather than relying solely on infrequent samples taken by larger agencies. Early adopters in three river basins have already deployed more than fifty units, and the dashboard now hosts roughly half a million data points.

Calibration remains the trickiest part of community-led environmental monitoring, the project's lead engineer acknowledged in a release. The kit ships with a calibration protocol and a quarterly check schedule designed to be performed without specialized lab equipment, using reference solutions available from any educational supply company.

The hardware files, firmware, and dashboard code are all available under a permissive license. The team is fundraising via small donations to support a paid documentation effort and to ship subsidized kits to school districts that are integrating the tool into earth-science curricula.
""",
            imageURL: "https://picsum.photos/seed/demo3/600/400",
            source: "Open Hardware Journal",
            category: "Tech",
            publishedAt: ago(hours: 6),
            bias: nil
        ),

        Article(
            id: demoID(4),
            title: "Small-Town Bakery Becomes Unexpected Hub for Civic Discussion",
            excerpt: "A weekly 'coffee and questions' morning hosted by a local bakery has drawn in residents, town staff, and visiting researchers studying community trust.",
            body: """
A small-town bakery on the main street of a 4,000-resident community has, almost by accident, become the most reliable place in the county for face-to-face civic conversation. The owners began hosting an open Tuesday-morning "coffee and questions" hour two years ago after several customers asked for a low-pressure place to talk about town affairs.

The format is intentionally unstructured: town staff, including the planning director and the public-works supervisor, rotate through on a volunteer basis to answer questions about ongoing projects. Residents drop in for fifteen minutes or two hours; there is no agenda and no recording.

Researchers studying small-community trust have begun visiting the bakery to interview participants. Their preliminary findings, presented at a regional civic-engagement conference last month, suggest that the bakery's combination of informal setting and the consistent presence of town staff has materially improved residents' self-reported trust in local government over the past two years.

The owners have politely declined to franchise the format. They say the model only works because it is theirs, and because the staff who attend genuinely want to be there. Other communities interested in adapting the idea, they suggest, should look first for the local volunteer who already wants to host.
""",
            imageURL: "https://picsum.photos/seed/demo4/600/400",
            source: "Regional Public Radio",
            category: "Politics",
            publishedAt: ago(hours: 8),
            bias: nil
        ),

        Article(
            id: demoID(5),
            title: "New Garden-Based Math Curriculum Shows Strong Gains in Pilot Schools",
            excerpt: "Third- and fourth-grade students who participated in a garden-integrated math curriculum outperformed peers in measurement and fractions, a year-end evaluation found.",
            body: """
A year-end evaluation of a garden-integrated math curriculum running in eleven pilot elementary schools found that participating third- and fourth-grade students outperformed comparison classrooms on measurement, fractions, and proportional reasoning by an average of nine percentile points. The curriculum was developed by a regional teachers' cooperative and combines weekly outdoor lessons in school gardens with conventional classroom instruction.

The curriculum's authors emphasized that they did not set out to produce a test-score intervention. The program's primary goals are engagement, confidence, and the development of a tactile sense of math as something used in the physical world. Improved test results are, in their telling, a downstream consequence of those primary aims.

Teachers participating in the pilot reported that students who had previously struggled with abstract fractions found the topic more approachable when working with measuring jugs in the garden. One teacher noted that several students who would shut down at a worksheet would readily reason about half versus a third of a watering can.

The cooperative is preparing materials for a wider release at the start of the next academic year. Schools without on-site garden space are receiving a modified version of the curriculum that uses a portable container-garden setup that can be wheeled between classrooms.
""",
            imageURL: "https://picsum.photos/seed/demo5/600/400",
            source: "Education Practice Quarterly",
            category: "Science",
            publishedAt: ago(hours: 10),
            bias: nil
        ),

        Article(
            id: demoID(6),
            title: "Regional Bus Cooperative Reaches Milestone of One Million Annual Riders",
            excerpt: "A small-county transit cooperative crossed the one-million-rides mark for the first time, driven by a redesigned route map and consistent on-time performance.",
            body: """
A regional transit cooperative serving four small counties announced this week that it had recorded its first one-million-rider year, more than doubling the ridership level of three years ago. The cooperative attributes the growth to a fully redesigned route map introduced two years ago and to a sustained on-time performance rate above 92%.

The redesign reduced the total number of stops by 18% but increased frequency on the remaining stops, a tradeoff that early surveys suggested most riders preferred. The cooperative also introduced timed transfers at three hub stops, allowing riders changing routes to do so reliably without long waits.

Operationally, the cooperative has invested heavily in maintenance and driver retention. Average vehicle downtime is at a multi-year low, and the driver workforce has stabilized after a difficult two-year hiring environment. Driver wages were raised twice during that period, funded in part by a small fare adjustment and a state operating-assistance grant.

The board is now studying whether to extend service hours into late evening on the two highest-demand corridors. A community comment process is open through the end of the month, and a decision is expected at the next board meeting.
""",
            imageURL: "https://picsum.photos/seed/demo6/600/400",
            source: "Transit Practice Notes",
            category: "Business",
            publishedAt: ago(hours: 12),
            bias: nil
        ),

        Article(
            id: demoID(7),
            title: "Wildlife Crossing Project Documents First Safe Passage of Mountain Lion Family",
            excerpt: "Camera traps captured a mother mountain lion and two cubs using the new highway overpass, the first family group recorded since the structure opened.",
            body: """
Camera traps maintained by a state wildlife agency captured a mother mountain lion and two cubs traversing a recently completed highway overpass last week, the first family group documented using the structure since it opened. Biologists involved with the project described the footage as a meaningful confirmation that the crossing is functioning as designed.

The overpass, a vegetated land bridge spanning a six-lane highway, was completed two years ago at the conclusion of a decade-long planning effort. It is the largest dedicated wildlife crossing in the state and was sized specifically to be wide and quiet enough that wide-ranging carnivores would tolerate using it. Earlier camera footage had shown adult males and a few unrelated females using the bridge but no family groups.

Biologists caution against drawing conclusions from a single observation but note that the appearance of cubs is precisely the population-recovery signal the project was intended to enable. Genetic isolation has been a long-running concern for the small mountain-lion population on the northern side of the highway, and any successful family movement across the structure incrementally improves connectivity.

Monitoring will continue for at least another decade, with results published annually. Several other states have sent delegations to study the crossing as part of their own infrastructure planning.
""",
            imageURL: "https://picsum.photos/seed/demo7/600/400",
            source: "Wildlife Monitor",
            category: "Science",
            publishedAt: ago(hours: 14),
            bias: nil
        ),

        Article(
            id: demoID(8),
            title: "Independent Bookshops Report Steady Growth for Fifth Consecutive Year",
            excerpt: "A trade association survey of independent booksellers found average revenue growth of 7% over the past year, with strongest gains in stores that host community events.",
            body: """
A trade association survey of independent booksellers found that average revenue grew by 7% over the past year across reporting stores, marking a fifth consecutive year of growth. The strongest performers were stores that host frequent community events such as author readings, children's story hours, and book clubs.

Survey respondents emphasized that the growth has come almost entirely from in-person foot traffic rather than online ordering. The association's executive director described the broader trend as a reassertion of physical retail spaces as community gathering points, not just transaction sites.

Margins remain tight, particularly for stores in high-rent areas. Several respondents noted that the principal challenge is not customer demand but rather the cost of staying in beloved storefronts as commercial rents continue to rise. A handful of stores have moved to slightly less central locations and report that loyal customers have followed them.

The association is preparing a small-store toolkit that distills practices from the highest-growth respondents, including event planning templates and a cooperative-buying program for shared inventory risk on niche titles.
""",
            imageURL: "https://picsum.photos/seed/demo8/600/400",
            source: "Independent Trade Review",
            category: "Business",
            publishedAt: ago(hours: 16),
            bias: nil
        ),

        Article(
            id: demoID(9),
            title: "Community Choir Premieres Composition Written During Pandemic Lockdown",
            excerpt: "A 90-voice community choir performed the long-delayed premiere of a multi-movement work composed by one of its members during the early months of the pandemic.",
            body: """
A 90-voice community choir performed the long-delayed premiere of a four-movement work composed by one of its members during the early months of the pandemic. The piece, scored for choir and small chamber ensemble, had been assembled remotely over several months in 2020 and had been waiting for an in-person premiere ever since.

The composer, an amateur musician and full-time elementary-school teacher, said the piece grew out of recordings she made during evening walks in her neighborhood when nothing else was open. She layered field recordings of birdsong and distant traffic with sketches of harmonies she heard in her head, eventually shaping the material into a cohesive work.

The premiere drew a sell-out crowd to a community church that has hosted the choir's concerts for over a decade. The performance was followed by a question-and-answer session in which the composer thanked the choir for trusting an unusual project and credited her colleagues' patience for keeping the music alive through several aborted rehearsal cycles.

A recording of the premiere is being mastered by a regional public-radio station and is expected to be broadcast later this season as part of the station's ongoing series highlighting amateur composers.
""",
            imageURL: "https://picsum.photos/seed/demo9/600/400",
            source: "Community Arts Bulletin",
            category: "Entertainment",
            publishedAt: ago(hours: 18),
            bias: nil
        ),

        Article(
            id: demoID(10),
            title: "Volunteer Astronomy Group Confirms Discovery of New Variable Star",
            excerpt: "An amateur astronomy collective documented and confirmed a previously uncatalogued variable star, with their measurements accepted by a major variable-star database.",
            body: """
A volunteer astronomy collective announced that an uncatalogued variable star they had been monitoring for the past eighteen months has been formally accepted into the principal international variable-star database. The acceptance follows independent confirmation from two amateur observatories and a final review by a professional astronomer who serves as a database referee.

The star, identified during routine survey work by one of the group's members using a backyard 8-inch telescope, varies in brightness by approximately 0.4 magnitudes on a roughly 6.3-day cycle. The light curve is consistent with a particular subclass of pulsating variables, though additional spectroscopic work would be needed to confirm the classification.

The collective's coordinator noted that volunteer-driven variable-star astronomy has a long history and remains one of the few areas of astronomical research in which non-professional observations contribute meaningfully to the published record. A new generation of inexpensive astronomical cameras has lowered the barrier to participation considerably.

The group has begun coordinating with a graduate student at a university observatory who will attempt to obtain a spectrum of the star during her next observing run. Should that effort succeed, it would be cited alongside the discovery report in the database entry.
""",
            imageURL: "https://picsum.photos/seed/demo10/600/400",
            source: "Amateur Astronomy Notes",
            category: "Science",
            publishedAt: ago(hours: 20),
            bias: nil
        ),

        Article(
            id: demoID(11),
            title: "Mid-Sized City Adopts Open Standard for Civic Data Publication",
            excerpt: "A mid-sized city's data office formally adopted an open civic-data standard for permits, budgets, and public-meeting records, joining a network of dozens of other municipalities.",
            body: """
The data office of a mid-sized city of roughly 180,000 residents has formally adopted an open civic-data publication standard for its permit records, budget filings, and public-meeting minutes. The adoption brings the city into a network of more than seventy other municipalities that publish records in a common machine-readable format.

The director of the data office said the standard was chosen primarily for its low maintenance burden. The format is plain JSON with a small schema, and existing internal systems were able to produce conforming outputs with minor adjustments. The office was deliberate about not adopting a heavyweight platform that would require ongoing license costs.

Civic-technology volunteers in the city have already begun building third-party tools on top of the published data. One early example is a permit-search interface that allows residents to look up the status of any building permit by address, which is a substantially faster experience than the city's existing internal portal.

The data office plans to publish quarterly reports on access patterns and to adjust the published datasets as community feedback accumulates. A volunteer working group is assisting with the prioritization process.
""",
            imageURL: "https://picsum.photos/seed/demo11/600/400",
            source: "Civic Tech Quarterly",
            category: "Tech",
            publishedAt: ago(hours: 22),
            bias: nil
        ),

        Article(
            id: demoID(12),
            title: "Regional Farmers Market Launches Cooperative Cold-Chain Service",
            excerpt: "Vendors at a regional farmers market have pooled resources to operate a shared refrigerated trailer, allowing smaller producers to reach buyers further from home.",
            body: """
Vendors at a regional farmers market have organized a cooperative cold-chain service in which a shared refrigerated trailer rotates among member farms during pickup days. The arrangement allows smaller producers — many of whom previously could not justify the cost of their own refrigerated transportation — to reach buyers further from their farms.

The cooperative is owned by twelve participating farms, each of which contributed an equal share of the down payment on the trailer. Operating costs, including a part-time driver and fuel, are split based on each farm's monthly use. A simple booking system on a shared spreadsheet allocates trailer time, with conflicts resolved by rotation.

In its first six months, the trailer has enabled at least three farms to begin supplying restaurants in a city about ninety minutes away — a distance that previously was logistically infeasible without compromising product quality. Two of those farms reported that the new restaurant accounts now make up a meaningful share of their weekly revenue.

The cooperative is now considering whether to add a second trailer to handle peak-season demand and whether to expand membership to a few additional producers who have asked to join. A decision is expected at the cooperative's next quarterly meeting.
""",
            imageURL: "https://picsum.photos/seed/demo12/600/400",
            source: "Local Food Economics",
            category: "Business",
            publishedAt: ago(hours: 26),
            bias: nil
        ),

        Article(
            id: demoID(13),
            title: "Retired Teachers Launch Free After-School Reading Program",
            excerpt: "A group of retired educators has organized a no-cost after-school reading program serving children in grades K-3 at a local community center.",
            body: """
A group of retired teachers has organized a no-cost after-school reading program for children in grades K-3, operating four afternoons a week at a local community center. The program serves about forty children at any given time, with a one-to-three ratio of trained volunteers to students.

The program leans on the participating volunteers' decades of classroom experience but is structured to keep the atmosphere distinctly informal. Children rotate through brief reading sessions, a small-group game tied to the day's book, and a snack break during which volunteers chat with the kids about whatever they like. Parents and guardians have praised the model in surveys for the warmth of the environment.

The program funds itself through a small grant from a local community foundation and through in-kind donations of books from the network of volunteers' former colleagues. Snack costs are covered by the community center as part of its broader after-school programming.

Several of the volunteers have begun offering a once-monthly Saturday workshop for parents on supporting early reading at home. Demand for the workshop has consistently exceeded available seats since it began.
""",
            imageURL: "https://picsum.photos/seed/demo13/600/400",
            source: "Community Education Notes",
            category: "Politics",
            publishedAt: ago(hours: 30),
            bias: nil
        ),

        Article(
            id: demoID(14),
            title: "Independent Film Festival Highlights Documentaries from First-Time Directors",
            excerpt: "A regional film festival's documentary track this year is composed entirely of first-time directors, with selections ranging from a study of small-town libraries to a profile of a community bicycle co-op.",
            body: """
A regional film festival's documentary track this year is composed entirely of first-time directors, a programming choice the festival's organizers describe as deliberate rather than accidental. The selections range widely in subject matter, from a study of small-town public libraries to a profile of a community bicycle cooperative.

The festival received roughly 320 documentary submissions and selected fourteen for the program. The programming director said the selection emphasized works in which the director's relationship to the subject was clearly personal — films made because the director cared about the topic rather than because it was commercially obvious.

Audience response on opening weekend was strong, with several screenings selling out and a number of post-screening discussions running well beyond their scheduled time. One first-time director, an elementary-school librarian, said the experience of watching her own film with a roomful of strangers had been disorienting in the best possible way.

The festival's organizers are considering whether to maintain the first-time-director focus in future years or to reserve a portion of each future program for emerging filmmakers while opening the rest to all submissions. A decision will be made after the post-festival debrief.
""",
            imageURL: "https://picsum.photos/seed/demo14/600/400",
            source: "Regional Arts Review",
            category: "Entertainment",
            publishedAt: ago(hours: 36),
            bias: nil
        ),

        Article(
            id: demoID(15),
            title: "University Research Team Publishes Open Dataset of Soil-Health Measurements",
            excerpt: "A multi-year research project has released its full soil-health dataset, comprising measurements from 240 agricultural plots across three watersheds.",
            body: """
A multi-year research project led by an applied-agriculture program has released its full soil-health dataset, comprising measurements from 240 agricultural plots across three watersheds. The release accompanies a peer-reviewed paper describing the methodology and headline findings, and is intended to enable secondary analyses by other researchers.

The dataset covers four years of seasonal measurements including organic matter, microbial activity, water-holding capacity, and a panel of nutrient indicators. Plots represent a deliberate mix of conventional, no-till, and cover-cropped management approaches, with consistent measurement protocols across all sites.

The lead author noted that the original published analysis answers only a small fraction of the questions the dataset can support. Releasing the full data is intended to invite other researchers to investigate questions outside the original team's scope, particularly around the interaction of management practices with local climate variability.

A small documentation team has been funded to maintain the dataset and respond to questions for at least the next three years, after which long-term archival hosting will be transferred to a regional agricultural data repository.
""",
            imageURL: "https://picsum.photos/seed/demo15/600/400",
            source: "Open Agricultural Science",
            category: "Science",
            publishedAt: ago(hours: 44),
            bias: nil
        ),
    ]

    static let articles: [Article] = [

        // MARK: - Tech (4)
        Article(
            id: stableID(1),
            title: "Apple Unveils M4 Ultra With Breakthrough Neural Engine Performance",
            excerpt: "Apple's latest chip pushes the boundary of on-device AI, delivering up to 40 trillion operations per second. The M4 Ultra redefines what's possible on desktop hardware without a cloud connection.",
            body: """
Apple stunned the developer community today by introducing the M4 Ultra, the most powerful chip the company has ever shipped for its Mac lineup. Built on TSMC's second-generation 3-nanometer process, the M4 Ultra integrates two M4 Max dies using Apple's UltraFusion interconnect, yielding a 32-core CPU, a 128-core GPU, and a Neural Engine capable of 40 TOPS.

The Neural Engine is the headline figure. At 40 trillion operations per second, the M4 Ultra is nearly double the performance of its predecessor and allows large language models that previously required cloud APIs to run entirely on-device with sub-second latency. Apple demonstrated a real-time photo description system and a coding assistant that generated responses in milliseconds, both running locally.

Memory bandwidth has also leaped to 800 GB/s, a number that had previously been the exclusive domain of data-center accelerators. Apple claims this allows the M4 Ultra to outperform discrete GPU configurations costing several times more for specific creative and machine-learning workloads.

Developers attending the event were given early access to Xcode tooling that targets the new Neural Engine, including a compiler pass that automatically vectorizes transformer attention layers. Several studios reported that video-generation workflows that once required remote rendering can now run in real time on a Mac Pro fitted with the M4 Ultra.

The chip will debut inside a new Mac Pro and a refreshed Mac Studio, both available for order starting next month. Pricing remains in line with previous generations. Apple's software engineering team also announced that macOS updates will begin shipping Neural Engine-accelerated versions of its own first-party apps, including Photos intelligent search and Xcode code completion.
""",
            imageURL: "https://picsum.photos/seed/101/600/400",
            source: "The Verge",
            category: "Tech",
            publishedAt: ago(hours: 2),
            bias: nil
        ),

        Article(
            id: stableID(2),
            title: "OpenAI Ships GPT-5 With Native Real-Time Video Understanding",
            excerpt: "GPT-5 can watch, describe, and reason about live video streams, marking a significant leap beyond text and static images. Early testers report the model narrating surgical procedures and sports plays with near-human accuracy.",
            body: """
OpenAI on Tuesday released GPT-5, introducing native real-time video understanding alongside substantial improvements in reasoning and code generation. The model can ingest a live video feed and produce a running narrative, answer questions about what it observes, and flag anomalies—all at under 500 milliseconds of latency.

The company demonstrated the capability using a live basketball game, asking GPT-5 to identify the play being run and predict the outcome. In all five demonstration clips the model correctly identified the offensive scheme and offered probability estimates for each possible shot that proved accurate against the recorded results.

Beyond video, OpenAI says GPT-5 scores 20 percentage points higher than GPT-4o on the GPQA Diamond benchmark for graduate-level scientific reasoning and achieves near-perfect scores on the AIME 2025 mathematics competition. The improvements stem from a new reinforcement learning pipeline that emphasizes multi-step reasoning traces rather than raw token prediction.

Safety researchers at the company published a separate technical report describing mitigations built into the video understanding system. Key among them is a real-time filter that prevents the model from responding to requests that involve surveillance of private individuals without consent, and a provenance layer that logs every video query for compliance auditing.

Pricing for GPT-5 starts at $0.015 per 1,000 input tokens, roughly three times the cost of GPT-4o. OpenAI announced tiered access, with enterprise customers receiving higher rate limits and on-premises deployment options for sensitive workloads. The API is available today for all paid developer tiers.
""",
            imageURL: "https://picsum.photos/seed/102/600/400",
            source: "Wired",
            category: "Tech",
            publishedAt: ago(hours: 5),
            bias: nil
        ),

        Article(
            id: stableID(3),
            title: "Google DeepMind's Gemini 2 Ultra Tops Every Major AI Benchmark",
            excerpt: "In a sweeping evaluation across coding, reasoning, and scientific tasks, Gemini 2 Ultra outperformed every competing model available today. Google says the results reflect a new training paradigm it calls 'chain-of-thought distillation.'",
            body: """
Google DeepMind released Gemini 2 Ultra overnight, and by morning independent researchers had replicated the benchmark claims: the model achieves state-of-the-art results on HumanEval for coding, MMLU for general knowledge, MATH for mathematics, and GPQA Diamond for scientific reasoning—all simultaneously.

The company attributes the gains to chain-of-thought distillation, a technique in which a very large teacher model generates detailed reasoning traces that a smaller student model is trained to reproduce. The effect is a model that reasons with the thoroughness of a billion-parameter architecture while operating at the inference cost of a fraction of that size.

Google also disclosed that Gemini 2 Ultra has a context window of 2 million tokens, large enough to process an entire software repository or a multi-hour audio recording in a single inference call. The practical implication for enterprise users is that retrieval-augmented generation pipelines can be simplified or eliminated entirely for many workloads.

Third-party evaluations from AI safety organization METR found that the model exhibits significantly improved instruction-following and reduced hallucination rates compared to its predecessor. On a suite of factual-grounding tasks, Gemini 2 Ultra refused to answer when uncertain rather than confabulating, a behavior the evaluators described as a meaningful safety improvement.

Access is rolling out through Google AI Studio and the Gemini API over the coming week. A Workspace integration will bring the model's capabilities directly into Google Docs and Sheets for subscribers on the Business and Enterprise tiers.
""",
            imageURL: nil,
            source: "TechCrunch",
            category: "Tech",
            publishedAt: ago(hours: 8),
            bias: nil
        ),

        Article(
            id: stableID(4),
            title: "SpaceX Successfully Tests Starship's Full Reusable Heat Shield System",
            excerpt: "For the first time, Starship completed a full entry, descent, and catch sequence with no heat shield tile replacements required for a second flight. The milestone brings fully reusable super-heavy rockets significantly closer to reality.",
            body: """
SpaceX achieved a pivotal milestone on Monday when Starship completed its seventh integrated flight test, successfully re-entering the atmosphere and being caught by the Mechazilla arms at Starbase in Texas—for the second consecutive time using the same vehicle, without replacing a single heat shield tile.

The significance of that last detail cannot be overstated. Rapid reusability at scale demands that the thermal protection system survive repeated entries without refurbishment. Earlier Starship tests had required replacement of hundreds of tiles between flights. This flight used the same tile configuration as Flight 6, and post-recovery inspection confirmed zero tile loss and no structural damage to the windward surface.

SpaceX's materials team spent eighteen months reformulating the tile bonding adhesive and redesigning the tile geometry around the vehicle's leading edges, where heating is most intense. The new tiles use a graded density foam core that manages thermal gradient more efficiently, and the bonding compound can withstand ten times the peel force of the original specification.

Elon Musk confirmed on X that the next step is a 48-hour turnaround goal for the booster—the time between landing and the next launch. Achieving this would make Starship the fastest-reusing orbital-class rocket ever built, and would be a prerequisite for the point-to-point Earth travel use case that SpaceX has been developing in parallel with NASA's Artemis lunar missions.

NASA watched the test closely. Starship's Human Landing System variant is central to the agency's plan to return astronauts to the lunar surface, and confidence in the thermal protection system is a gating factor for crewed missions. Program managers said they were "very encouraged" by today's results.
""",
            imageURL: "https://picsum.photos/seed/104/600/400",
            source: "Ars Technica",
            category: "Tech",
            publishedAt: ago(hours: 12),
            bias: nil
        ),

        // MARK: - Business (3)
        Article(
            id: stableID(5),
            title: "Federal Reserve Signals Three Rate Cuts Possible This Year",
            excerpt: "Fed Chair Jerome Powell hinted at a faster-than-expected easing cycle, pointing to cooling inflation and a softer labor market. Markets rallied sharply on the news, with the S&P 500 gaining 1.8% by close.",
            body: """
Federal Reserve Chair Jerome Powell on Wednesday signaled that the central bank could lower its benchmark interest rate three times before year-end, a more aggressive easing path than investors had anticipated. Speaking at a press conference following the Federal Open Market Committee's April meeting, Powell cited a meaningful deceleration in core PCE inflation and softening labor demand as the conditions driving the new assessment.

Core personal consumption expenditures inflation, the Fed's preferred price gauge, came in at 2.2% year-over-year for March, the lowest reading since the current rate-hiking cycle began. Meanwhile, nonfarm payroll gains have averaged 140,000 per month over the past quarter, down from a peak of over 300,000 in 2022. Powell described this as a labor market "normalizing rather than deteriorating."

Financial markets responded enthusiastically. The S&P 500 closed up 1.8%, the Nasdaq gained 2.4%, and the yield on the two-year Treasury note fell 14 basis points to its lowest level in over a year. The iShares 20+ Year Treasury Bond ETF climbed 1.6% as traders positioned for the falling-rate environment.

Not all FOMC members share Powell's optimism. Three dissents were recorded in favor of holding rates steady, reflecting concerns that services inflation remains stubbornly elevated and that cutting too quickly could reignite price pressures. The minutes from the meeting will be released in three weeks and are expected to show a vigorous internal debate.

Economists at major banks revised their rate forecasts upward following the announcement. Goldman Sachs now projects the fed funds target range ending the year at 3.75–4.00%, down from 5.25–5.50% at the recent peak. The first cut is expected at the June meeting, with subsequent reductions in September and December contingent on incoming data.
""",
            imageURL: "https://picsum.photos/seed/201/600/400",
            source: "Wall Street Journal",
            category: "Business",
            publishedAt: ago(hours: 3),
            bias: nil
        ),

        Article(
            id: stableID(6),
            title: "Amazon Acquires AI Infrastructure Startup Meridian for $2.4 Billion",
            excerpt: "The deal gives Amazon Web Services ownership of Meridian's proprietary silicon design tools and a team of 400 chip architects. Analysts say the acquisition accelerates AWS's bid to reduce its dependence on Nvidia GPUs.",
            body: """
Amazon has agreed to acquire Meridian Systems, a three-year-old AI infrastructure startup, for $2.4 billion in cash, the company announced Thursday. Meridian built a suite of software tools that automate the design and verification of custom AI accelerator chips, along with a team of 400 chip architects who will join Amazon Web Services.

The strategic rationale is straightforward: AWS is the world's largest cloud provider, and its compute costs are dominated by the price of renting or purchasing Nvidia GPUs. By accelerating development of its own custom silicon—the Trainium and Inferentia lines—Amazon can bring down inference costs and offer competitive pricing that rivals cannot match with commodity hardware.

Meridian's tooling reportedly reduces chip tape-out time from eighteen months to under six, a dramatic compression that allows hardware teams to iterate on designs at software-like velocity. The startup had previously licensed its tools to three unnamed semiconductor companies; all three licensing agreements will be wound down post-acquisition.

The deal is subject to regulatory review by the Federal Trade Commission, which has been scrutinizing large technology acquisitions in the AI space. Amazon's legal team expressed confidence that the transaction will clear review, noting that Meridian has no consumer-facing products and a minimal market share in any defined product market.

Meridian's co-founder and CEO, Dr. Priya Anand, will serve as VP of Custom Silicon at AWS and will report directly to the company's CEO of technology infrastructure. She described the acquisition as "a chance to deploy our tools at a scale we could never have reached independently, and to prove that American semiconductor design can remain the global standard."
""",
            imageURL: "https://picsum.photos/seed/202/600/400",
            source: "Bloomberg",
            category: "Business",
            publishedAt: ago(hours: 6),
            bias: nil
        ),

        Article(
            id: stableID(7),
            title: "Tesla Stock Surges 22% After Record-Breaking Quarter in Southeast Asia",
            excerpt: "Deliveries in Southeast Asia rose 180% year-over-year, driven by a newly opened Gigafactory in Indonesia. The results silenced near-term bears and pushed Tesla's market capitalization back above $900 billion.",
            body: """
Tesla reported a record-breaking first quarter on Thursday, beating Wall Street estimates on every major metric and triggering a 22% single-day stock surge that added more than $150 billion to the company's market capitalization. The key driver was a 180% year-over-year increase in Southeast Asian deliveries, fueled by the company's first Gigafactory in Indonesia, which reached full production capacity ahead of schedule.

The Indonesia facility, located outside Jakarta, benefits from proximity to some of the world's largest nickel reserves—a critical battery input—and from a government incentive package that waives import duties on battery cells for the first five years of operation. CEO Elon Musk said the plant produced 38,000 vehicles in Q1, and that capacity would expand to 60,000 per quarter by year-end.

Globally, Tesla delivered 512,000 vehicles in the quarter, up 28% from a year ago and well ahead of the 470,000 consensus estimate. Automotive gross margin excluding credits came in at 19.3%, a full percentage point above guidance, as cost-cutting initiatives in the Model 3 and Model Y supply chains continued to yield results.

The energy generation and storage segment also impressed, with Megapack deployments of 8.2 GWh setting another quarterly record. This business now contributes nearly 12% of total revenue and carries higher margins than the automotive unit, a shift that Chief Financial Officer Vaibhav Taneja described as "the beginning of a fundamental change in Tesla's business mix."

Analysts at Morgan Stanley raised their twelve-month price target from $210 to $280 following the report, citing improved visibility on the company's autonomous vehicle timeline and the growing contribution of the energy segment. The stock closed at $271, its highest level in fourteen months.
""",
            imageURL: nil,
            source: "Reuters",
            category: "Business",
            publishedAt: ago(hours: 14),
            bias: nil
        ),

        // MARK: - Politics (3)
        Article(
            id: stableID(8),
            title: "Senate Passes Landmark Climate and Clean Energy Act in Narrow Vote",
            excerpt: "The legislation, which passed 52-48, allocates $380 billion for clean energy infrastructure and imposes a national clean electricity standard. It now heads to the House, where passage is uncertain.",
            body: """
The United States Senate passed the Climate and Clean Energy Act on Friday in a 52-to-48 vote, the most significant federal climate legislation in decades. The bill allocates $380 billion over ten years for clean energy infrastructure, imposes a national clean electricity standard requiring utilities to source 80% of their power from zero-carbon sources by 2035, and creates a new carbon fee on industrial emissions above a threshold of 25,000 metric tons per year.

Four Republican senators crossed the aisle to provide the margin of victory, citing the estimated 400,000 manufacturing jobs the legislation is projected to create in states where traditional energy industries have been declining. The bill had stalled twice over the past two years before a late amendment removed a provision banning new natural gas pipeline permits, a change that secured the necessary crossover votes.

Environmental groups called the passage a historic milestone while acknowledging it falls short of what scientists say is needed to limit warming to 1.5 degrees Celsius. The Sierra Club estimated that the bill's provisions, fully implemented, would reduce U.S. greenhouse gas emissions by approximately 45% below 2005 levels by 2035, compared to the 50-52% target in the Paris Agreement commitment.

The bill now moves to the House of Representatives, where the math is more difficult. The speaker has agreed to bring it to the floor for a vote within 60 days but has not committed to supporting passage. Moderate members from fossil-fuel-producing districts have expressed concern about the carbon fee's impact on energy prices in their constituencies.

The White House praised the Senate's action and said the President would sign the bill immediately if it reaches the Oval Office in its current form. Administration officials have begun preparing implementation guidance for the Environmental Protection Agency and the Department of Energy in anticipation of final passage.
""",
            imageURL: "https://picsum.photos/seed/301/600/400",
            source: "NPR",
            category: "Politics",
            publishedAt: ago(hours: 4),
            bias: nil
        ),

        Article(
            id: stableID(9),
            title: "NATO Allies Commit $40 Billion in New Defense Spending at Brussels Summit",
            excerpt: "All 32 member nations pledged to sustain defense spending above 2% of GDP, with twelve countries committing to reach 3% by 2027. The summit also approved a new rapid-response force of 100,000 troops.",
            body: """
NATO leaders emerged from a two-day summit in Brussels on Thursday having secured pledges totaling more than $40 billion in new defense spending across the alliance, with all 32 member nations formally committing to maintain expenditure above 2% of GDP for the first time in the organization's history. Twelve members committed to reaching the 3% threshold by 2027.

The centerpiece of the summit's communiqué was the establishment of a new Allied Rapid Response Force comprising 100,000 troops drawn from member nations, capable of deploying to a threat zone within five days. The force will maintain a rotating headquarters in Poland and will conduct quarterly exercises to ensure interoperability across its multinational composition.

Secretary-General Mark Rutte described the commitments as a "generational shift" in how European democracies think about collective defense. "We spent the Cold War at high readiness. Then we took a holiday. That holiday is definitively over," he told reporters at the closing press conference.

The summit also approved a $500 million fund for accelerating development of counter-drone technology, an area where alliance members identified a critical capability gap following recent conflicts. The fund will be managed by the NATO Defense Innovation Accelerator and will prioritize projects that can field operational systems within 24 months.

In a notable development, the alliance endorsed a new doctrine explicitly addressing cyberattacks against critical infrastructure, stating for the first time that a destructive cyberattack on any member nation could trigger the collective defense provisions of Article 5. Legal scholars noted that the definition of "destructive" remains deliberately ambiguous, preserving deterrence flexibility.
""",
            imageURL: "https://picsum.photos/seed/302/600/400",
            source: "Foreign Policy",
            category: "Politics",
            publishedAt: ago(hours: 18),
            bias: nil
        ),

        Article(
            id: stableID(10),
            title: "Supreme Court to Hear Landmark AI Copyright Case in October Term",
            excerpt: "The case, which pits a coalition of authors against a major AI company, will determine whether training large language models on copyrighted text constitutes fair use. A ruling is expected by June next year.",
            body: """
The Supreme Court of the United States announced Monday that it will hear Holt v. Luminary AI in its October term, granting certiorari in a case that legal scholars say could fundamentally reshape the intellectual property landscape for artificial intelligence. The case was brought by a coalition of novelists, journalists, and publishers who allege that Luminary AI trained its flagship language model on their copyrighted works without authorization or compensation.

At issue is whether the ingestion of copyrighted text during the training phase of a large language model qualifies as fair use under Section 107 of the Copyright Act. Luminary AI argues that training is a transformative use because the model does not reproduce text verbatim but instead extracts statistical patterns, much as a human reader absorbs stylistic influences without infringing copyright. The plaintiffs counter that the scale of ingestion—billions of works—and its direct commercial benefit to the company makes the use anything but fair.

The Ninth Circuit had ruled in favor of Luminary AI, finding that the transformative nature of the use and the lack of market substitution weighed in the company's favor. The Second Circuit reached the opposite conclusion in a parallel case, creating the circuit split that made Supreme Court review virtually inevitable.

A broad coalition of technology companies, academic institutions, and civil society organizations has filed amicus briefs on both sides. The AI industry warns that ruling against fair use would impose retroactive liability threatening the viability of every foundation model built to date. Authors' groups argue that without protection, the economic basis for human creative work will erode.

The Court typically hears cases argued in October through April and issues decisions by the end of June. A ruling is therefore expected by June of next year, just in time to influence pending copyright legislation in both houses of Congress.
""",
            imageURL: "https://picsum.photos/seed/303/600/400",
            source: "Politico",
            category: "Politics",
            publishedAt: ago(hours: 22),
            bias: nil
        ),

        // MARK: - Sports (3)
        Article(
            id: stableID(11),
            title: "Golden State Warriors Land Three-Time MVP in Blockbuster Trade",
            excerpt: "The Warriors sent four first-round picks and two All-Stars to acquire the league's reigning MVP, instantly transforming them into championship contenders. Bay Area fans erupted after the announcement late Thursday night.",
            body: """
The Golden State Warriors executed the most significant trade of the current NBA season late Thursday, acquiring reigning three-time MVP Damian Okafor from the Chicago Bulls in exchange for four first-round draft picks, one unprotected, and two All-Star caliber veterans. The deal was finalized minutes before the trade deadline and sent shockwaves through the league.

Okafor, 27, has averaged 31.4 points, 8.6 assists, and 5.2 rebounds per game this season, leading the Bulls to the top seed in the East despite a thin supporting cast. His arrival in Golden State reunites him with head coach Steve Kerr, who coached him at the 2024 Paris Olympics, where the two reportedly developed a strong rapport.

Warriors president of basketball operations Bob Myers described the trade as a "now or never" decision given the franchise's championship window. "Our core is entering its prime. We had the assets. When a player of Damian's caliber becomes available, you move," he said. The Warriors currently sit third in the Western Conference and are projected to climb to the top seed with Okafor in the lineup.

Chicago receives a significant rebuilding haul. The unprotected 2026 first-round pick carries particular value given Golden State's mid-tier positioning, and the two veterans—both aged 28—provide immediate competitive talent for a Bulls squad that expects to contend again within two years.

The transaction is contingent on Okafor passing a physical, which is scheduled for Friday morning in San Francisco. Assuming clearance, he is expected to debut in a nationally televised game on Sunday. Ticket resale prices for that game rose over 400% within minutes of the trade announcement.
""",
            imageURL: "https://picsum.photos/seed/401/600/400",
            source: "ESPN",
            category: "Sports",
            publishedAt: ago(hours: 7),
            bias: nil
        ),

        Article(
            id: stableID(12),
            title: "England Reaches World Cup Final With Dramatic Penalty Shootout Win",
            excerpt: "England beat France 4-3 on penalties after a pulsating 1-1 draw, with goalkeeper Jordan Pickford saving two spot kicks to send the nation into euphoria. They will face Argentina in Sunday's final.",
            body: """
England is heading to a FIFA World Cup final for the first time since 1966 after defeating France 4-3 in a penalty shootout on Wednesday night, following a tension-saturated 1-1 draw at the Estadio Azteca in Mexico City. Goalkeeper Jordan Pickford was the hero, saving spot kicks from Kylian Mbappé and Antoine Griezmann in a shootout that will be replayed for generations.

The match itself was an absorbing contest between two of the tournament's most technically accomplished sides. Jude Bellingham opened the scoring with a towering header from a Phil Foden corner in the 34th minute, but Mbappé equalized from the penalty spot after a foul by Trent Alexander-Arnold on the edge of the box that the referee controversially upgraded to a penalty following a VAR review.

Extra time produced two near-misses for each side but no further goals, pushing the match to penalties. England converted all four of their spot kicks, with Harry Kane, Bellingham, Bukayo Saka, and Foden all finding the net. Pickford then saved from Mbappé—diving to his right—and palmed away Griezmann's effort before Marcus Rashford sent the final kick past Maignan to send the England bench into delirium.

Manager Gareth Southgate, who endured the heartbreak of two previous tournament exits via penalty defeat during his tenure, pumped his fists as the final kick went in and was then immediately mobbed by his coaching staff. "I've run out of words for what this group of players means to me," he told ITV Sport afterward.

England will face Argentina in Sunday's final, a rematch of the 1986 classic. The South Americans advanced earlier in the day after defeating Brazil 2-1 in the other semifinal. Kick-off is scheduled for 4 p.m. local time in Mexico City.
""",
            imageURL: "https://picsum.photos/seed/402/600/400",
            source: "BBC Sport",
            category: "Sports",
            publishedAt: ago(hours: 16),
            bias: nil
        ),

        Article(
            id: stableID(13),
            title: "Serena Williams Returns to Wimbledon for Landmark Charity Exhibition",
            excerpt: "Four years after her retirement, Williams played an exhibition match at Centre Court to raise funds for underprivileged youth tennis programs. The 41,000-strong crowd gave her two standing ovations.",
            body: """
Serena Williams walked onto Centre Court at Wimbledon on Tuesday for the first time since her 2022 retirement, playing a charity exhibition match against British number one Emma Raducanu to a full house of 41,000 people who rose twice to give the 23-time Grand Slam champion standing ovations. The event raised £4.2 million for the Williams Sisters Foundation's youth tennis scholarship program.

Williams, 43, insisted the match would be purely for fun and that she had no ambitions to return to competitive tennis. True to her word, she played with evident joy rather than ferocity, trading rallies and occasionally gesturing to the crowd with theatrical mock-exasperation at her own errors. She won the first set 6-4 before conceding the second 3-6 in an outcome that many observers suspected was choreographed to ensure the sell-out crowd got its money's worth of drama.

"I've missed this," she told the crowd during the on-court interview. "Not the pressure—I don't miss the pressure at all. But the sound of a rally, the feel of grass under my feet, the way Centre Court just... breathes with you. That I've missed every single day."

Raducanu, gracious throughout, said playing against Williams was "the closest thing to a lesson I've ever had on a tennis court. She's still seeing the ball completely differently from everyone else." The two had trained together for three days in advance of the exhibition and appeared genuinely fond of each other.

The Williams Sisters Foundation was established in 2019 and has since funded over 3,000 scholarships for children ages 6-18 in underserved communities across the United States and the United Kingdom. Tuesday's event brings total charitable fundraising through tennis exhibitions to over £12 million.
""",
            imageURL: nil,
            source: "The Guardian",
            category: "Sports",
            publishedAt: ago(hours: 30),
            bias: nil
        ),

        // MARK: - Science (4)
        Article(
            id: stableID(14),
            title: "Scientists Confirm Gravitational Wave Signature of Binary Neutron Star Merger",
            excerpt: "A joint detection by LIGO, Virgo, and KAGRA has pinpointed a neutron star collision 130 million light-years away with unprecedented precision. The event also produced a gamma-ray burst visible to space telescopes within seconds.",
            body: """
An international team of physicists announced the most detailed observation of a binary neutron star merger to date, describing gravitational wave data from a collision 130 million light-years away that was simultaneously observed by four ground-based detectors and three space telescopes within a window of 1.7 seconds. The event, designated GW250412, was detected on April 12 by the LIGO facilities in Washington and Louisiana, Italy's Virgo detector, and Japan's KAGRA observatory.

The precision of the multi-messenger observation allowed researchers to localize the event to a patch of sky roughly the size of the full Moon—four times better than any previous neutron star merger detection. NASA's Fermi Gamma-ray Space Telescope and the Neil Gehrels Swift Observatory independently confirmed the gamma-ray burst, while the ESA Integral satellite measured the high-energy afterglow spectrum.

The data provide the tightest constraints yet on the equation of state of dense nuclear matter. By modeling how the two neutron stars deformed each other under their mutual gravitational field before merging, the team has narrowed the range of possible radii for a 1.4-solar-mass neutron star to between 11.8 and 12.4 kilometers—a precision that rules out several competing nuclear physics models.

Of particular excitement to cosmologists is a refined measurement of the Hubble constant derived from the event. Using the gravitational wave "standard siren" technique pioneered in 2017, the team calculates H₀ at 68.2 ± 3.1 km/s/Mpc. This measurement is statistically independent of both the cosmic distance ladder and the cosmic microwave background methods, and falls squarely between the two discrepant values currently fueling the Hubble tension debate.

The full dataset will be publicly released in 72 hours through the Gravitational Wave Open Science Center, and sixteen follow-up papers are in preparation covering topics from nucleosynthesis to tests of general relativity.
""",
            imageURL: "https://picsum.photos/seed/501/600/400",
            source: "Nature",
            category: "Science",
            publishedAt: ago(hours: 9),
            bias: nil
        ),

        Article(
            id: stableID(15),
            title: "mRNA Cancer Vaccine Shows 91% Efficacy in Phase III Trial",
            excerpt: "Moderna and Merck's personalized melanoma vaccine prevented recurrence in 91% of high-risk patients over a three-year follow-up. The results could pave the way for FDA approval by the end of this year.",
            body: """
Moderna and Merck reported three-year follow-up data from the KEYNOTE-942 Phase III trial on Wednesday, showing that their personalized mRNA cancer vaccine reduced the risk of melanoma recurrence or death by 91% when combined with Keytruda immunotherapy compared to Keytruda alone. The data, presented at the American Association for Cancer Research annual meeting, exceeded the company's own projections and were described by independent oncologists as "practice-changing."

The vaccine, designated mRNA-4157/V940, is manufactured individually for each patient using genomic sequencing of their tumor to identify 34 unique neoantigens—proteins present on the cancer cells but not on healthy tissue. The mRNA instructions are then synthesized and encapsulated in lipid nanoparticles, the same delivery mechanism used in COVID-19 vaccines, and administered as a series of nine injections over roughly six months.

Of the 157 patients in the experimental arm, 143 remained recurrence-free at the three-year mark. In the control group receiving Keytruda alone, 87 of 150 patients experienced recurrence or death. The difference in overall survival was similarly dramatic: 96% of vaccine recipients were alive at three years versus 83% in the control group.

Side effects were consistent with those seen in earlier trials: injection site reactions, fatigue, and mild fever in the days following each dose. No serious adverse events attributable to the vaccine were reported. The safety profile compares favorably to existing adjuvant therapies for high-risk melanoma.

The companies plan to submit a Biologics License Application to the FDA in the third quarter of this year, with a decision expected by late 2026 or early 2027 under standard review timelines. They also announced the expansion of the vaccine program to non-small-cell lung cancer and bladder cancer, with Phase II trials enrolling now.
""",
            imageURL: "https://picsum.photos/seed/502/600/400",
            source: "STAT News",
            category: "Science",
            publishedAt: ago(hours: 11),
            bias: nil
        ),

        Article(
            id: stableID(16),
            title: "NASA's Europa Clipper Detects Organic Molecules in Plume Sample",
            excerpt: "During a close flyby of Jupiter's moon Europa, the spacecraft's mass spectrometer captured complex organic compounds in an ejected plume. Scientists say the finding significantly raises the probability of a habitable subsurface ocean.",
            body: """
NASA's Europa Clipper spacecraft made its closest flyby of Jupiter's moon Europa on April 9, diving to within 25 kilometers of the surface and passing directly through an active water plume that ejected material from the moon's subsurface ocean through cracks in the ice shell. Preliminary analysis of the mass spectrometer data, released Monday, has identified a range of complex organic molecules including fatty acid precursors and amino acid analogues.

The detection of organic chemistry in a plume sample is the most significant astrobiology result since the Cassini spacecraft detected molecular hydrogen in Saturn's moon Enceladus in 2017. While it does not constitute evidence of life, it confirms that Europa's ocean contains the chemical building blocks necessary for life as we know it, and that those compounds can survive transport from the ocean through the ice and into space.

Principal investigator Dr. Britney Schmidt of Cornell University described the finding at a press briefing as "exactly the kind of result we designed this mission to find." She cautioned that multiple alternative abiotic pathways could produce the detected compounds and that distinguishing biological from non-biological origins would require either a lander or a sample return mission. Europa Clipper itself has no capability to determine biological activity.

The spacecraft will conduct 49 additional flybys of Europa over the next four years, each at a different location and altitude. Scientists hope that analyzing plume material from multiple ejection sites will build a compositional map of the ocean chemistry and identify regions where water circulation and chemical gradients are most favorable to life.

NASA and ESA are jointly studying proposals for a Europa lander mission that could drill through the ice shell and sample the liquid ocean directly. A formal mission concept review is scheduled for 2027, with a potential launch window opening in the early 2030s.
""",
            imageURL: "https://picsum.photos/seed/503/600/400",
            source: "Scientific American",
            category: "Science",
            publishedAt: ago(hours: 20),
            bias: nil
        ),

        Article(
            id: stableID(17),
            title: "Harvard Team Grows Functional Kidney Tissue From Human Stem Cells",
            excerpt: "Researchers have produced kidney organoids that can filter waste and concentrate urine at near-physiological levels, a first for the field. The advance could eventually reduce dependence on transplant waiting lists.",
            body: """
A team of bioengineers and nephrologists at Harvard Medical School and the Wyss Institute reported Thursday the successful cultivation of kidney organoids capable of performing functional filtration and urine concentration at levels approaching those of natural human kidney tissue. The work, published in Nature Biomedical Engineering, represents a significant leap forward in the decade-long effort to grow transplantable organs from a patient's own cells.

Previous kidney organoids had recapitulated the structure of nephrons—the basic filtration units of the kidney—but had failed to organize into the functional architecture needed for net filtration. The Harvard team solved this problem by engineering a biodegradable scaffold shaped to mimic the cortical-medullary structure of a native kidney, seeded it with induced pluripotent stem cells derived from human donors, and then subjected the constructs to dynamic perfusion that gradually imposed physiological flow rates and pressure gradients.

After 28 days of maturation, the organoids achieved a glomerular filtration rate of approximately 40% of native kidney function in an ex vivo perfusion circuit. More importantly, the collecting ducts concentrated urine by a factor of 3.5 above plasma levels, demonstrating an active transport function that had never been observed in a laboratory-grown kidney analog.

The constructs were also shown to respond appropriately to vasopressin, the hormone that regulates water reabsorption, providing evidence that the endocrine signaling pathways are functional. In a final experiment, organoids were perfused with blood from uremic patients and demonstrably reduced creatinine and urea concentrations, the toxins that accumulate in kidney failure.

The path to clinical transplantation remains long. The organoids currently measure approximately 2 centimeters in diameter, far smaller than the 10-centimeter adult kidney, and long-term vascularization—connecting the tissue to a patient's blood supply—has not yet been demonstrated in vivo. The team projects that a small-scale human feasibility study is 7–10 years away.
""",
            imageURL: "https://picsum.photos/seed/504/600/400",
            source: "MIT Technology Review",
            category: "Science",
            publishedAt: ago(hours: 36),
            bias: nil
        ),

        // MARK: - Entertainment (3)
        Article(
            id: stableID(18),
            title: "Dune: Messiah Shatters Opening Weekend Box Office Records",
            excerpt: "Denis Villeneuve's third Dune film earned $312 million globally in its first three days, the largest opening ever for a science fiction film. Critics have called it the best of the trilogy.",
            body: """
Denis Villeneuve's Dune: Messiah opened to a staggering $312 million globally over its first three days in theaters, surpassing the previous record for a science fiction opening set by Avatar: The Way of Water in 2022 and landing as the third-largest opening weekend in cinema history. The domestic total of $127 million exceeded even the most optimistic pre-release projections from industry analysts.

The film completes the adaptation of Frank Herbert's Dune Messiah novel, the direct sequel to Dune, and follows Paul Atreides as the god-emperor of a galactic civilization he never wanted to rule. Timothée Chalamet reprises the lead role alongside returning cast members Zendaya, Josh Brolin, and Rebecca Ferguson, with Florence Pugh joining as Princess Irulan and Austin Butler appearing in an expanded role as the menacing Feyd-Rautha.

Critics have been rapturous. The film holds a 97% approval rating on Rotten Tomatoes, with several reviewers calling it Villeneuve's masterpiece and drawing comparisons to The Return of the King and The Empire Strikes Back as rare trilogy conclusions that surpass their predecessors. Particular praise has been directed at Greig Fraser's cinematography, Hans Zimmer's score, and a third-act battle sequence described by Empire Magazine as "the most viscerally overwhelming 12 minutes in modern blockbuster filmmaking."

The cultural event status of the release contributed to the numbers: three major cities reported sold-out IMAX screenings for the entire first week, and social media was dominated by fan reactions from midnight screenings that trended globally for over eighteen hours.

Warner Bros. confirmed immediately after the weekend results that a fourth film—adapting Children of Dune—has been greenlit, with Villeneuve attached as director and the full core cast expected to return. Production is tentatively scheduled to begin in late 2026.
""",
            imageURL: "https://picsum.photos/seed/601/600/400",
            source: "Variety",
            category: "Entertainment",
            publishedAt: ago(hours: 13),
            bias: nil
        ),

        Article(
            id: stableID(19),
            title: "Taylor Swift Announces 'The Manuscript' World Tour for 2027",
            excerpt: "Swift's next tour will span 110 dates across six continents, supporting her eleventh studio album. Pre-sale tickets sold out in under four minutes in every market, crashing multiple ticketing platforms.",
            body: """
Taylor Swift announced The Manuscript World Tour on Thursday via a surprise Instagram post that appeared at midnight Eastern time, accompanied by a cryptic poem and the cover art for her eleventh studio album, The Manuscript, due for release in September. The tour will run from February through December 2027, comprising 110 dates across North America, Europe, South America, Asia, Australia, and—for the first time—Africa.

The album, described in the post as "a letter I've been writing for a long time," appears to be a departure from the pop maximalism of The Eras Tour-era records. The cover art shows a handwritten notebook on a bare wooden desk, and the three-line poem accompanying the announcement references themes of memory, truth, and authorship that fan communities immediately began analyzing for sonic and lyrical clues.

Pre-sale tickets went on sale at 10 a.m. in each market's local time, and reports of platform crashes poured in from every region. Ticketmaster's queue system reached 4.2 million virtual arrivals within the first minute in North America, and verified fan registration—which required listening hours and merchandise purchases to qualify—had enrolled over 18 million accounts before the pre-sale opened. Tickets in most markets were sold out within four minutes.

Live Nation president Joe Berchtold described the demand as "unlike anything we have ever measured in the history of live music." The company has worked with concert venues to increase floor capacity by 15–20% compared to Eras Tour configurations, and has partnered with four streaming services to offer a live broadcast option for fans unable to attend in person.

Swift's team announced that 5% of all ticket revenue will be donated to literacy nonprofits in each city on the tour route. Based on projected gross revenue figures in the entertainment press, analysts estimate the donation could exceed $100 million over the tour's run.
""",
            imageURL: "https://picsum.photos/seed/602/600/400",
            source: "Rolling Stone",
            category: "Entertainment",
            publishedAt: ago(hours: 25),
            bias: nil
        ),

        Article(
            id: stableID(20),
            title: "Netflix Documentary 'Apollo: The Hidden History' Wins Three Emmy Awards",
            excerpt: "The five-part series, which used declassified documents and AI-restored footage to tell the untold stories of the Apollo program's support workers, took home Outstanding Documentary, Directing, and Editing.",
            body: """
Netflix's Apollo: The Hidden History swept the documentary categories at the 77th Primetime Emmy Awards on Sunday night, winning Outstanding Documentary Series, Outstanding Directing for a Documentary (Ava DuVernay), and Outstanding Picture Editing for a Nonfiction Program. The five-part series has been praised for shifting the narrative of the Apollo program from its famous astronauts to the 400,000 engineers, mathematicians, and seamstresses—many of them women and people of color—who made the missions possible.

The series drew on 40,000 pages of declassified NASA documents obtained through Freedom of Information Act requests spanning eight years, and pioneered a technique that used AI upscaling and frame interpolation to restore archival 16mm footage to 4K resolution. The visual result was praised in reviews as transformative—audiences who had grown up with the grainy, jerky images of the Apollo era encountered it instead with the clarity of a modern documentary.

DuVernay's directing approach focused on intimate character studies rather than mission narratives. The standout episode, "The Stitchers," followed the women at the ILC Dover plant in Delaware who hand-sewed the spacesuits, tracing the stories of three seamstresses whose names have never appeared in a history book despite their work being literally the last barrier between the astronauts and the vacuum of space.

The series has been credited with sparking a resurgence of public interest in the space program and in archival documentary as a form. Applications to NASA's historical archive access program increased 340% in the month following the premiere, and ILC Dover reported that the episode about the suit seamstresses generated more media coverage in one week than the company had received in the previous decade.

Netflix has greenlit a follow-up series covering the Space Shuttle program, also from DuVernay's production company Array, with a planned premiere in late 2027.
""",
            imageURL: "https://picsum.photos/seed/603/600/400",
            source: "Hollywood Reporter",
            category: "Entertainment",
            publishedAt: ago(hours: 40),
            bias: nil
        )
    ]
}
