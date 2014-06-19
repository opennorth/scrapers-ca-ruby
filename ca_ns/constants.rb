# Names are not linked if there are errors in the given name or family name, if
# the honorary prefix is missing, unabbreviated or missing a period, or if the
# name is of a role.
TYPOS = {
  "christopher d'entromont" => 'http://nslegislature.ca/index.php/people/members/christopher_a_dentremont1', # family name
  "d'enteremont" => 'http://nslegislature.ca/index.php/people/members/christopher_a_dentremont1', # family name
  "d'entremount" => 'http://nslegislature.ca/index.php/people/members/christopher_a_dentremont1', # family name
  'bekcy kent' => 'http://nslegislature.ca/index.php/people/members/Becky_Kent', # given name
  'diane whalen' => 'http://nslegislature.ca/index.php/people/members/diana_whalen1', # given name
  'gordon gosse' => 'http://nslegislature.ca/index.php/people/members/gordie_gosse1', # given name
  'harold therault' => 'http://nslegislature.ca/index.php/people/members/Harold_Theriault', # family name
  'jaimie baillie' => 'http://nslegislature.ca/index.php/people/members/jamie_baillie', # given name
  'mailyn more' => 'http://nslegislature.ca/index.php/people/members/Marilyn_More', # given name
  'mariyln more' => 'http://nslegislature.ca/index.php/people/members/Marilyn_More', # given name
  'maureen macdonld' => 'http://nslegislature.ca/index.php/people/members/Maureen_MacDonald', # family name
  'michael samson' => 'http://nslegislature.ca/index.php/people/members/michel_p_samson1', # given name
  'michele raymond' => 'http://nslegislature.ca/index.php/people/members/Michele_Raymond', # unlinked occurs before linked
  'pan eyking' => 'http://nslegislature.ca/index.php/people/members/pam_eyking', # given name
  'peterson-rayfuse' => 'http://nslegislature.ca/index.php/people/members/Denise_Peterson-Rafuse', # family name
  'ross laundry' => 'http://nslegislature.ca/index.php/people/members/Ross_Landry', # family name
  'macneil' => 'http://nslegislature.ca/index.php/people/members/Stephen_McNeil', # family name
  'stephen macneil' => 'http://nslegislature.ca/index.php/people/members/Stephen_McNeil', # family name
  'bellieveau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1', # family name
  'sterling bellieau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1', # family name
  'sterling bellieveau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1', # family name
  'sterlng belliveau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1', # given name
  'the lieutenant governor' => 'http://nslegislature.ca/index.php/people/lt-gov/', # role-based
  'vickie conrad' => 'http://nslegislature.ca/index.php/people/members/Vicki_Conrad', # given name
  'william estabooks' => 'http://nslegislature.ca/index.php/people/members/Bill_Estabrooks', # both names
  # Role-based
  'chairman' => 'http://nslegislature.ca/index.php/people/speaker', # Chairman always seems to refer to the Speaker
  'the administrator' => 'http://nslegislature.ca/index.php/people/lt-gov/',
  'sergeant-at-arms' => 'http://nslegislature.ca/index.php/people/offices/sergeant-at-arms',
}

HEADING_TYPOS = {
  'MOTIONS UNDER RULE 5(5)' => 'MOTION UNDER RULE 5(5)',
  'NOTICE OF QUESTION FOR WRITTEN ANSWERS' => 'NOTICE OF QUESTIONS FOR WRITTEN ANSWERS',
  'NOTICES OF MOTION UNDER RULE (32)(3)' => 'NOTICES OF MOTION UNDER RULE 32(3)',
  "OPPOSTION MEMBERS' BUSINESS" => "OPPOSITION MEMBERS' BUSINESS",
  'ORAL QUESTION PUT BY MEMBERS' => 'ORAL QUESTIONS PUT BY MEMBERS',
  'Pursuant to Rule 30' => 'PURSUANT TO RULE 30',
  'Pursuant to Rule 30(1)' => 'PURSUANT TO RULE 30(1)',
  'PRESENTING REPORT OF COMMITTEES' => 'PRESENTING REPORTS OF COMMITTEES',
  'PRESENTING REPORTS OF COMMIITTEES' => 'PRESENTING REPORTS OF COMMITTEES',
  'PRESENTING REPORTS OF COMMITEES' => 'PRESENTING REPORTS OF COMMITTEES',
  'TABLING REPORTS, REGLATIONS AND OTHER PAPERS' => 'TABLING REPORTS, REGULATIONS AND OTHER PAPERS',
  /\AQUESTION No\b/ => 'QUESTION NO',
  /\ARESOLTUION\b/ => 'RESOLUTION',
  /\ARESOLTUTION\b/ => 'RESOLUTION',
  /\ARESOLUION\b/ => 'RESOLUTION',
  /\ARESOLUTION (?=\d)/ => 'RESOLUTION NO. ',
  /\ARESOLUTION NO.(?! )/ => 'RESOLUTION NO. ',
  /\ARESOLUTIONNO\b/ => 'RESOLUTION NO',
  /\ARESOLUTIONS NO\b/ => 'RESOLUTION NO',
  /\ARESOLUTON\b/ => 'RESOLUTION',
}

HEADINGS = [
  'ADJOURNMENT',
  'ANSWERS TO WRITTEN QUESTIONS',
  'COLLABORATIVE EMERGENCY CENTRES',
  'ELIGIBILITY BREAKDOWN',
  'GOVERNMENT BUSINESS',
  'GOVERNMENT MOTIONS',
  'GOVERNMENT NOTICES OF MOTION',
  'INQUIRY TERMS OF REF.',
  'INTL. DAY FOR ELIMINATION OF VIOLENCE AGAINST WOMEN',
  'INTRODUCTION OF BILLS',
  'MOTION UNDER RULE 43',
  'MOTION UNDER RULE 5(5)',
  'MOTIONS OTHER THAN GOVERNMENT MOTIONS',
  'NOTICE OF QUESTIONS FOR WRITTEN ANSWERS',
  'NOTICES OF MOTION',
  'NOTICES OF MOTION UNDER RULE 32(3)',
  'ON MOTION FOR SUPPLY',
  "OPPOSITION MEMBERS' BUSINESS",
  'ORAL QUESTIONS PUT BY MEMBERS',
  'ORAL QUESTIONS PUT BY MEMBERS TO MINISTERS',
  'ORDERS OF THE DAY',
  'PRESENTING AND READING PETITIONS',
  'PRESENTING REPORTS OF COMMITTEES',
  'PRIVATE AND LOCAL BILLS FOR SECOND READING',
  'PRIVATE AND LOCAL BILLS FOR THIRD READING',
  "PRIVATE MEMBERS' PUBLIC BILLS FOR SECOND READING",
  "PRIVATE MEMBERS' PUBLIC BILLS FOR THIRD READING",
  'PUBLIC BILLS FOR SECOND READING',
  'PUBLIC BILLS FOR THIRD READING',
  'PURSUANT TO RULE 30',
  'PURSUANT TO RULE 30(1)',
  'RESPONSE:',
  'RESPONSES',
  'RESPONSIBILITY ASSUME',
  'STATEMENTS BY MINISTERS',
  'TABLING REPORTS, REGULATIONS AND OTHER PAPERS',
]

HEADINGS_RE = [
  /\ABill No\. \d+ - /,
  /\AQUESTION NO\. \d+\z/,
  /\ARESOLUTION NO\. \d+\z/,
  /\AGiven on \S+ \d{1,2}, 20\d\d\z/,
  /\ATabled \S+ \d{1,2}, 20\d\d\z/,
  # Issue-based headings that have no useful markers.
  # EMO: ASPY BAY/ST. MARGARETS VILLAGE/BAY ST. LAWRENCE
  # ERDT: ACADIANS (N.S.)
  # GAMING: HAMMONDS PLAINS GAMING CTR.
  # JUSTICE: N.S. HOME FOR COLORED CHILDREN -
  # N.S. HOME FOR COLORED CHILDREN:
  # PREM: FIRST CONTRACT ARBITRATION/UNIONIZATION RATE:
  # SNSMR: SALVATION ARMY GOOD NEIGHBOUR FUND
  # STATUS OF WOMEN: DOMESTIC VIOLENCE ACTION PLAN
  /\A(?:EMO|ERDT|GAMING|JUSTICE|N\.S\. HOME FOR COLORED CHILDREN|PREM|SNSMR|STATUS OF WOMEN)\b/,
]
