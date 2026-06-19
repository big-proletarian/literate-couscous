const ideologies = {
    "Marxism-Leninism": {
        a1: [55, 25, 20], a2: [70, 5, 25], a3: [40, 45, 15], a4: [45, 40, 15],
        a5: [75, 15, 10], a6: [60, 15, 25], a7: 65, a8: [40, 15, 45],
        desc: "A revolutionary ideology based on the writings of Marx, Engels, and Lenin, emphasizing the vanguard party, democratic centralism, and the dictatorship of the proletariat as the path to communism."
    },
    "Trotskyism (Orthodox)": {
        a1: [45, 40, 15], a2: [80, 5, 15], a3: [10, 30, 60], a4: [85, 5, 10],
        a5: [70, 15, 15], a6: [50, 20, 30], a7: 75, a8: [90, 5, 5],
        desc: "Following Leon Trotsky's theory of permanent revolution, emphasizing international revolution, workers' democracy, and opposition to Stalinist bureaucracy."
    },
    "Trotskyism (Cliffite)": {
        a1: [70, 10, 20], a2: [75, 5, 20], a3: [40, 50, 10], a4: [95, 0, 5],
        a5: [60, 20, 20], a6: [40, 25, 35], a7: 80, a8: [85, 10, 5],
        desc: "A variant of Trotskyism associated with Tony Cliff, characterized by the theory that the USSR was state capitalist and emphasis on socialism from below."
    },
    "Trotskyism (Shachtmanite)": {
        a1: [30, 50, 20], a2: [65, 10, 25], a3: [10, 30, 60], a4: [70, 10, 20],
        a5: [55, 25, 20], a6: [35, 30, 35], a7: 80, a8: [70, 10, 20],
        desc: "A heterodox Trotskyist tendency associated with Max Shachtman, characterized by the theory of bureaucratic collectivism and a third camp position."
    },
    "Left-Communism (Bordigist)": {
        a1: [80, 10, 10], a2: [85, 10, 5], a3: [75, 15, 10], a4: [85, 10, 5],
        a5: [85, 5, 10], a6: [50, 20, 30], a7: 60, a8: [80, 10, 10],
        desc: "Following Amadeo Bordiga, emphasizing organic centralism, the invariance of the communist programme, and rejection of all democratic participation and frontism."
    },
    "Left-Communism (ICT)": {
        a1: [80, 5, 15], a2: [85, 5, 10], a3: [15, 50, 35], a4: [90, 5, 5],
        a5: [55, 10, 35], a6: [30, 40, 30], a7: 80, a8: [85, 5, 10],
        desc: "The Internationalist Communist Tendency emphasizes the party as political guide while maintaining that workers' councils are the organs of proletarian power."
    },
    "Council Communism": {
        a1: [75, 5, 20], a2: [70, 10, 20], a3: [5, 40, 55], a4: [75, 5, 20],
        a5: [10, 15, 75], a6: [35, 25, 40], a7: 75, a8: [85, 5, 10],
        desc: "Inspired by Pannekoek and Gorter, emphasizing workers' councils as the supreme organ of working-class self-organization, rejecting vanguard parties and trade unions."
    },
    "Communisation": {
        a1: [80, 5, 15], a2: [65, 15, 20], a3: [5, 15, 80], a4: [65, 5, 30],
        a5: [5, 10, 85], a6: [15, 30, 55], a7: 85, a8: [80, 5, 15],
        desc: "An ultra-left tendency arguing that communism must be established immediately through the revolutionary process, without any transitional period."
    },
    "Autonomism": {
        a1: [55, 10, 35], a2: [50, 15, 35], a3: [5, 20, 75], a4: [50, 10, 40],
        a5: [10, 20, 70], a6: [15, 30, 55], a7: 85, a8: [70, 15, 15],
        desc: "Rooted in Italian operaismo, emphasizing autonomy of working-class struggle, the refusal of work, and building counter-power through direct action."
    },
    "Anarcho-Communism": {
        a1: [55, 5, 40], a2: [25, 45, 30], a3: [5, 10, 85], a4: [60, 5, 35],
        a5: [5, 20, 75], a6: [15, 40, 45], a7: 90, a8: [75, 10, 15],
        desc: "Following Kropotkin, advocating a stateless, classless society organized through voluntary federation of self-governing communes based on mutual aid."
    },
    "Insurrectionary Anarchism": {
        a1: [80, 5, 15], a2: [15, 60, 25], a3: [5, 5, 90], a4: [40, 10, 50],
        a5: [5, 10, 85], a6: [20, 35, 45], a7: 85, a8: [70, 10, 20],
        desc: "An anarchist tendency emphasizing immediate insurrection through informal affinity groups, rejecting formal organization and mediation between desire and action."
    },
    "Anarcho-Syndicalism": {
        a1: [50, 10, 40], a2: [20, 20, 60], a3: [5, 15, 80], a4: [65, 5, 30],
        a5: [5, 75, 20], a6: [35, 30, 35], a7: 80, a8: [75, 10, 15],
        desc: "An anarchist approach viewing revolutionary industrial unions as both the means of class struggle and the foundation of a future libertarian socialist society."
    },
    "Syndicalism": {
        a1: [45, 20, 35], a2: [20, 15, 65], a3: [10, 30, 60], a4: [55, 15, 30],
        a5: [10, 70, 20], a6: [45, 25, 30], a7: 70, a8: [65, 15, 20],
        desc: "A revolutionary movement centered on trade unions as the vehicle for class struggle and post-revolutionary economic organization."
    },
    "National Syndicalism": {
        a1: [50, 20, 30], a2: [10, 30, 60], a3: [35, 40, 25], a4: [5, 80, 15],
        a5: [20, 65, 15], a6: [55, 20, 25], a7: 20, a8: [15, 30, 55],
        desc: "A corporatist ideology combining syndicalist organizational forms with nationalism, seeking class collaboration through national unity."
    },
    "Fascism": {
        a1: [55, 15, 30], a2: [5, 55, 40], a3: [50, 40, 10], a4: [5, 85, 10],
        a5: [60, 25, 15], a6: [60, 20, 20], a7: 5, a8: [5, 25, 70],
        desc: "An authoritarian ultranationalist ideology characterized by dictatorial power, forcible suppression of opposition, and class collaboration through corporatism."
    },
    "National Bolshevism": {
        a1: [55, 20, 25], a2: [37.5, 30, 32.5], a3: [45, 42.5, 12.5], a4: [25, 62.5, 12.5],
        a5: [67.5, 20, 12.5], a6: [60, 17.5, 22.5], a7: 35, a8: [22.5, 20, 57.5],
        desc: "A syncretic ideology combining elements of Marxism-Leninism and Fascism, characterized by extreme nationalism, state socialism, and cultural conservatism."
    },
    "Strasserism": {
        a1: [38.3, 38.3, 23.4], a2: [19.2, 35, 45.8], a3: [48.3, 37.5, 14.2], a4: [21.7, 64.2, 14.1],
        a5: [62.5, 23.3, 14.2], a6: [48.4, 25.8, 25.8], a7: 38.3, a8: [0, 50, 50],
        desc: "A radical mass-action wing of Nazism associated with the Strasser brothers, emphasizing anti-capitalism, worker-based nationalism, and virulent antisemitism."
    },
    "Maoism": {
        a1: [70, 10, 20], a2: [55, 15, 30], a3: [35, 40, 25], a4: [35, 40, 25],
        a5: [65, 15, 20], a6: [55, 20, 25], a7: 65, a8: [50, 20, 30],
        desc: "A variant of Marxism-Leninism emphasizing the mass line, people's war, new democracy, and cultural revolution."
    },
    "Democratic Socialism": {
        a1: [15, 65, 20], a2: [25, 30, 45], a3: [35, 30, 35], a4: [45, 30, 25],
        a5: [55, 25, 20], a6: [25, 35, 40], a7: 80, a8: [45, 25, 30],
        desc: "Advocating democratic ownership and control of the means of production through electoral politics and gradual reform."
    },
    "Social Democracy": {
        a1: [5, 80, 15], a2: [15, 20, 65], a3: [50, 30, 20], a4: [35, 45, 20],
        a5: [60, 25, 15], a6: [25, 40, 35], a7: 75, a8: [20, 30, 50],
        desc: "A political ideology advocating economic and social interventions within capitalism including welfare state provisions and regulated markets."
    },
    "Eurocommunism": {
        a1: [15, 65, 20], a2: [45, 10, 45], a3: [35, 35, 30], a4: [40, 40, 20],
        a5: [60, 20, 20], a6: [30, 35, 35], a7: 75, a8: [35, 25, 40],
        desc: "A revisionist tendency advocating a parliamentary road to socialism independent of the Soviet Union, emphasizing broad democratic alliances."
    },
    "Eco-Socialism": {
        a1: [30, 30, 40], a2: [40, 25, 35], a3: [10, 25, 65], a4: [50, 10, 40],
        a5: [20, 30, 50], a6: [10, 55, 35], a7: 85, a8: [55, 20, 25],
        desc: "A synthesis of ecological and socialist thought, arguing that ecological destruction is inherent to capitalism."
    },
    "Anarcho-Primitivism": {
        a1: [60, 5, 35], a2: [10, 65, 25], a3: [5, 5, 90], a4: [15, 5, 80],
        a5: [5, 5, 90], a6: [5, 80, 15], a7: 50, a8: [50, 25, 25],
        desc: "A radical ecological anarchism critiquing civilization itself, advocating a return to pre-industrial modes of living in harmony with nature."
    },
    "Libertarian Socialism": {
        a1: [40, 15, 45], a2: [30, 30, 40], a3: [5, 15, 80], a4: [45, 10, 45],
        a5: [10, 30, 60], a6: [20, 35, 45], a7: 85, a8: [65, 15, 20],
        desc: "A broad anti-authoritarian socialist tradition rejecting both capitalism and authoritarian state socialism, emphasizing workers' self-management."
    },
    "Mutualism": {
        a1: [15, 25, 60], a2: [15, 30, 55], a3: [5, 10, 85], a4: [20, 10, 70],
        a5: [5, 40, 55], a6: [30, 30, 40], a7: 75, a8: [35, 45, 20],
        desc: "Following Proudhon, advocating a market socialist economy based on cooperatively owned enterprises and mutual credit."
    },
    "Guild Socialism": {
        a1: [15, 40, 45], a2: [15, 25, 60], a3: [15, 25, 60], a4: [25, 35, 40],
        a5: [10, 65, 25], a6: [40, 30, 30], a7: 60, a8: [40, 40, 20],
        desc: "Inspired by G.D.H. Cole, proposing industry organized into self-governing guilds of workers with the state handling consumption."
    },
    "Utopian Socialism": {
        a1: [10, 30, 60], a2: [5, 70, 25], a3: [10, 15, 75], a4: [25, 15, 60],
        a5: [10, 15, 75], a6: [15, 45, 40], a7: 75, a8: [30, 35, 35],
        desc: "Pre-Marxist socialist thought emphasizing model communities and moral persuasion rather than class struggle."
    },
    "Religious Socialism": {
        a1: [15, 40, 45], a2: [10, 60, 30], a3: [20, 25, 55], a4: [30, 30, 40],
        a5: [20, 20, 60], a6: [20, 45, 35], a7: 35, a8: [30, 30, 40],
        desc: "A synthesis of socialist economics with religious ethics, drawing on traditions such as liberation theology and Christian socialism."
    }
};
