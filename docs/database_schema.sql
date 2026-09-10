-- CreateTable
CREATE TABLE "tbprivileges" (
    "PK_privilege" SERIAL NOT NULL,
    "privilege" TEXT NOT NULL,
    "privilegeCode" TEXT NOT NULL,
    "privilegeType" TEXT NOT NULL,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbprivileges_pkey" PRIMARY KEY ("PK_privilege")
);

-- CreateTable
CREATE TABLE "tbcitizens" (
    "PK_citizen" SERIAL NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "CI" TEXT,
    "phoneNumber" TEXT NOT NULL,
    "email" TEXT,
    "password" TEXT,
    "profileImage" TEXT,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "actionHistory" JSONB,

    CONSTRAINT "tbcitizens_pkey" PRIMARY KEY ("PK_citizen")
);

-- CreateTable
CREATE TABLE "tbinstitutiontypes" (
    "PK_institutionType" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actionHistory" JSONB,

    CONSTRAINT "tbinstitutiontypes_pkey" PRIMARY KEY ("PK_institutionType")
);

-- CreateTable
CREATE TABLE "tbinstitutions" (
    "PK_institution" SERIAL NOT NULL,
    "FK_institutionType" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "acronym" TEXT,
    "phoneNumber" TEXT,
    "email" TEXT,
    "address" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "actionHistory" JSONB,

    CONSTRAINT "tbinstitutions_pkey" PRIMARY KEY ("PK_institution")
);

-- CreateTable
CREATE TABLE "tbsubinstitutions" (
    "PK_subinstitution" SERIAL NOT NULL,
    "FK_institution" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT,
    "phoneNumber" TEXT,
    "email" TEXT,
    "address" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "actionHistory" JSONB,

    CONSTRAINT "tbsubinstitutions_pkey" PRIMARY KEY ("PK_subinstitution")
);

-- CreateTable
CREATE TABLE "tbusers" (
    "PK_user" SERIAL NOT NULL,
    "FK_privilege" INTEGER NOT NULL,
    "FK_institution" INTEGER,
    "FK_subinstitution" INTEGER,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "actionHistory" JSONB,

    CONSTRAINT "tbusers_pkey" PRIMARY KEY ("PK_user")
);

-- CreateTable
CREATE TABLE "tbdevices" (
    "PK_device" SERIAL NOT NULL,
    "FK_citizen" INTEGER NOT NULL,
    "pushToken" TEXT,
    "device" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tbdevices_pkey" PRIMARY KEY ("PK_device")
);

-- CreateTable
CREATE TABLE "tbusersdevices" (
    "PK_device" SERIAL NOT NULL,
    "FK_user" INTEGER NOT NULL,
    "pushToken" TEXT,
    "device" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tbusersdevices_pkey" PRIMARY KEY ("PK_device")
);

-- CreateTable
CREATE TABLE "tbresourcetypes" (
    "PK_resourceType" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actionHistory" JSONB,

    CONSTRAINT "tbresourcetypes_pkey" PRIMARY KEY ("PK_resourceType")
);

-- CreateTable
CREATE TABLE "tbinstitutionservices" (
    "PK_institutionService" SERIAL NOT NULL,
    "FK_institution" INTEGER NOT NULL,
    "FK_resourceType" INTEGER NOT NULL,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actionHistory" JSONB,

    CONSTRAINT "tbinstitutionservices_pkey" PRIMARY KEY ("PK_institutionService")
);

-- CreateTable
CREATE TABLE "tbunits" (
    "PK_unit" SERIAL NOT NULL,
    "FK_institution" INTEGER NOT NULL,
    "FK_subinstitution" INTEGER,
    "FK_resourceType" INTEGER NOT NULL,
    "unitCode" TEXT NOT NULL,
    "unitName" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "status" TEXT NOT NULL,
    "isAvailable" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "actionHistory" JSONB,

    CONSTRAINT "tbunits_pkey" PRIMARY KEY ("PK_unit")
);

-- CreateTable
CREATE TABLE "tbemergencytypes" (
    "PK_emergencyType" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actionHistory" JSONB,

    CONSTRAINT "tbemergencytypes_pkey" PRIMARY KEY ("PK_emergencyType")
);

-- CreateTable
CREATE TABLE "tbemergencies" (
    "PK_emergency" SERIAL NOT NULL,
    "FK_citizen" INTEGER,
    "FK_emergencyType" INTEGER,
    "FK_parentEmergency" INTEGER,
    "emergencyCode" TEXT NOT NULL,
    "priority" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "isMainEmergency" BOOLEAN NOT NULL DEFAULT true,
    "reportCount" INTEGER NOT NULL DEFAULT 1,
    "description" TEXT,
    "affectedPersons" INTEGER,
    "affectedAnimals" INTEGER,
    "trappedPersons" INTEGER,
    "missingPersons" INTEGER,
    "reportedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "acceptedAt" TIMESTAMP(3),
    "resolvedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "actionHistory" JSONB,

    CONSTRAINT "tbemergencies_pkey" PRIMARY KEY ("PK_emergency")
);

-- CreateTable
CREATE TABLE "tbaisessions" (
    "PK_aiSession" SERIAL NOT NULL,
    "FK_citizen" INTEGER NOT NULL,
    "FK_emergency" INTEGER,
    "sessionStatus" TEXT NOT NULL,
    "initialIntent" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMP(3),

    CONSTRAINT "tbaisessions_pkey" PRIMARY KEY ("PK_aiSession")
);

-- CreateTable
CREATE TABLE "tbemergencyreports" (
    "PK_report" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "FK_citizen" INTEGER,
    "reportChannel" TEXT NOT NULL,
    "description" TEXT,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "isLinkedByAI" BOOLEAN NOT NULL DEFAULT false,
    "linkingConfidence" DOUBLE PRECISION,
    "distanceMetersFromMain" DOUBLE PRECISION,
    "reportedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbemergencyreports_pkey" PRIMARY KEY ("PK_report")
);

-- CreateTable
CREATE TABLE "tbemergencylocations" (
    "PK_location" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "accuracy" DOUBLE PRECISION,
    "address" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbemergencylocations_pkey" PRIMARY KEY ("PK_location")
);

-- CreateTable
CREATE TABLE "tbcalls" (
    "PK_call" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "callType" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "answeredAt" TIMESTAMP(3),
    "endedAt" TIMESTAMP(3),
    "durationSeconds" INTEGER,
    "transcription" TEXT,
    "audioUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actionHistory" JSONB,

    CONSTRAINT "tbcalls_pkey" PRIMARY KEY ("PK_call")
);

-- CreateTable
CREATE TABLE "tbemergencyrooms" (
    "PK_room" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "roomCode" TEXT NOT NULL,
    "isOpen" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "closedAt" TIMESTAMP(3),

    CONSTRAINT "tbemergencyrooms_pkey" PRIMARY KEY ("PK_room")
);

-- CreateTable
CREATE TABLE "tbemergencyroommembers" (
    "PK_roomMember" SERIAL NOT NULL,
    "FK_room" INTEGER NOT NULL,
    "FK_citizen" INTEGER,
    "FK_user" INTEGER,
    "FK_institution" INTEGER,
    "FK_unit" INTEGER,
    "memberRole" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leftAt" TIMESTAMP(3),
    "isActive" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "tbemergencyroommembers_pkey" PRIMARY KEY ("PK_roomMember")
);

-- CreateTable
CREATE TABLE "tbchatmessages" (
    "PK_chatMessage" SERIAL NOT NULL,
    "FK_room" INTEGER NOT NULL,
    "FK_citizen" INTEGER,
    "FK_user" INTEGER,
    "FK_institution" INTEGER,
    "FK_unit" INTEGER,
    "senderRole" TEXT NOT NULL,
    "senderName" TEXT NOT NULL,
    "messageType" TEXT NOT NULL,
    "message" TEXT,
    "fileUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbchatmessages_pkey" PRIMARY KEY ("PK_chatMessage")
);

-- CreateTable
CREATE TABLE "tbunitlocations" (
    "PK_unitLocation" SERIAL NOT NULL,
    "FK_unit" INTEGER NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "speed" DOUBLE PRECISION,
    "heading" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbunitlocations_pkey" PRIMARY KEY ("PK_unitLocation")
);

-- CreateTable
CREATE TABLE "tbevidences" (
    "PK_evidence" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "FK_citizen" INTEGER,
    "FK_user" INTEGER,
    "fileType" TEXT NOT NULL,
    "fileUrl" TEXT NOT NULL,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbevidences_pkey" PRIMARY KEY ("PK_evidence")
);

-- CreateTable
CREATE TABLE "tbemergencyviews" (
    "PK_emergencyView" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "FK_citizen" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbemergencyviews_pkey" PRIMARY KEY ("PK_emergencyView")
);

-- CreateTable
CREATE TABLE "tbemergencylikes" (
    "PK_emergencyLike" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "FK_citizen" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbemergencylikes_pkey" PRIMARY KEY ("PK_emergencyLike")
);

-- CreateTable
CREATE TABLE "tbaianalyses" (
    "PK_aiAnalysis" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "confidenceScore" DOUBLE PRECISION NOT NULL,
    "suggestedPriority" TEXT NOT NULL,
    "extractedEntities" JSONB NOT NULL,
    "rawResponse" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbaianalyses_pkey" PRIMARY KEY ("PK_aiAnalysis")
);

-- CreateTable
CREATE TABLE "tbemergencyrequirements" (
    "PK_requirement" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "FK_resourceType" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "status" TEXT NOT NULL DEFAULT 'PENDIENTE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbemergencyrequirements_pkey" PRIMARY KEY ("PK_requirement")
);

-- CreateTable
CREATE TABLE "tbemergencyassignments" (
    "PK_assignment" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "FK_institution" INTEGER NOT NULL,
    "FK_subinstitution" INTEGER,
    "FK_unit" INTEGER,
    "status" TEXT NOT NULL,
    "assignedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "acceptedAt" TIMESTAMP(3),
    "arrivedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),

    CONSTRAINT "tbemergencyassignments_pkey" PRIMARY KEY ("PK_assignment")
);

-- CreateTable
CREATE TABLE "tbassignmenttracking" (
    "PK_tracking" SERIAL NOT NULL,
    "FK_assignment" INTEGER NOT NULL,
    "FK_unit" INTEGER NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "speed" DOUBLE PRECISION,
    "heading" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbassignmenttracking_pkey" PRIMARY KEY ("PK_tracking")
);

-- CreateTable
CREATE TABLE "tbemergencystatushistory" (
    "PK_statusHistory" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "FK_user" INTEGER,
    "previousStatus" TEXT,
    "newStatus" TEXT NOT NULL,
    "changeReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbemergencystatushistory_pkey" PRIMARY KEY ("PK_statusHistory")
);

-- CreateTable
CREATE TABLE "tbemergencyprogressreports" (
    "PK_progressReport" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "FK_institution" INTEGER,
    "FK_user" INTEGER,
    "reportText" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbemergencyprogressreports_pkey" PRIMARY KEY ("PK_progressReport")
);

-- CreateTable
CREATE TABLE "tbnotifications" (
    "PK_notification" SERIAL NOT NULL,
    "FK_citizen" INTEGER,
    "FK_user" INTEGER,
    "FK_emergency" INTEGER,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "notificationType" TEXT NOT NULL,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbnotifications_pkey" PRIMARY KEY ("PK_notification")
);

-- CreateTable
CREATE TABLE "tbemergencydestinations" (
    "PK_destination" SERIAL NOT NULL,
    "FK_emergency" INTEGER NOT NULL,
    "FK_institution" INTEGER,
    "destinationName" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "arrivalEta" TIMESTAMP(3),
    "arrivedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbemergencydestinations_pkey" PRIMARY KEY ("PK_destination")
);

-- CreateIndex
CREATE UNIQUE INDEX "tbprivileges_privilege_key" ON "tbprivileges"("privilege");

-- CreateIndex
CREATE UNIQUE INDEX "tbprivileges_privilegeCode_key" ON "tbprivileges"("privilegeCode");

-- CreateIndex
CREATE UNIQUE INDEX "tbcitizens_CI_key" ON "tbcitizens"("CI");

-- CreateIndex
CREATE UNIQUE INDEX "tbcitizens_phoneNumber_key" ON "tbcitizens"("phoneNumber");

-- CreateIndex
CREATE UNIQUE INDEX "tbcitizens_email_key" ON "tbcitizens"("email");

-- CreateIndex
CREATE UNIQUE INDEX "tbinstitutiontypes_code_key" ON "tbinstitutiontypes"("code");

-- CreateIndex
CREATE INDEX "tbinstitutions_FK_institutionType_idx" ON "tbinstitutions"("FK_institutionType");

-- CreateIndex
CREATE INDEX "tbsubinstitutions_FK_institution_idx" ON "tbsubinstitutions"("FK_institution");

-- CreateIndex
CREATE UNIQUE INDEX "tbusers_email_key" ON "tbusers"("email");

-- CreateIndex
CREATE INDEX "tbusers_FK_privilege_idx" ON "tbusers"("FK_privilege");

-- CreateIndex
CREATE INDEX "tbusers_FK_institution_idx" ON "tbusers"("FK_institution");

-- CreateIndex
CREATE INDEX "tbusers_FK_subinstitution_idx" ON "tbusers"("FK_subinstitution");

-- CreateIndex
CREATE UNIQUE INDEX "tbdevices_FK_citizen_key" ON "tbdevices"("FK_citizen");

-- CreateIndex
CREATE UNIQUE INDEX "tbusersdevices_FK_user_key" ON "tbusersdevices"("FK_user");

-- CreateIndex
CREATE UNIQUE INDEX "tbresourcetypes_code_key" ON "tbresourcetypes"("code");

-- CreateIndex
CREATE INDEX "tbinstitutionservices_FK_institution_idx" ON "tbinstitutionservices"("FK_institution");

-- CreateIndex
CREATE INDEX "tbinstitutionservices_FK_resourceType_idx" ON "tbinstitutionservices"("FK_resourceType");

-- CreateIndex
CREATE UNIQUE INDEX "tbinstitutionservices_FK_institution_FK_resourceType_key" ON "tbinstitutionservices"("FK_institution", "FK_resourceType");

-- CreateIndex
CREATE UNIQUE INDEX "tbunits_unitCode_key" ON "tbunits"("unitCode");

-- CreateIndex
CREATE INDEX "tbunits_FK_institution_idx" ON "tbunits"("FK_institution");

-- CreateIndex
CREATE INDEX "tbunits_FK_resourceType_idx" ON "tbunits"("FK_resourceType");

-- CreateIndex
CREATE INDEX "tbunits_isAvailable_isActive_idx" ON "tbunits"("isAvailable", "isActive");

-- CreateIndex
CREATE UNIQUE INDEX "tbemergencytypes_code_key" ON "tbemergencytypes"("code");

-- CreateIndex
CREATE UNIQUE INDEX "tbemergencies_emergencyCode_key" ON "tbemergencies"("emergencyCode");

-- CreateIndex
CREATE INDEX "tbemergencies_FK_citizen_idx" ON "tbemergencies"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbemergencies_FK_emergencyType_idx" ON "tbemergencies"("FK_emergencyType");

-- CreateIndex
CREATE INDEX "tbemergencies_FK_parentEmergency_idx" ON "tbemergencies"("FK_parentEmergency");

-- CreateIndex
CREATE INDEX "tbemergencies_status_idx" ON "tbemergencies"("status");

-- CreateIndex
CREATE INDEX "tbemergencies_priority_idx" ON "tbemergencies"("priority");

-- CreateIndex
CREATE INDEX "tbemergencies_reportedAt_idx" ON "tbemergencies"("reportedAt");

-- CreateIndex
CREATE INDEX "tbaisessions_FK_citizen_idx" ON "tbaisessions"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbaisessions_FK_emergency_idx" ON "tbaisessions"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyreports_FK_emergency_idx" ON "tbemergencyreports"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyreports_FK_citizen_idx" ON "tbemergencyreports"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbemergencyreports_isLinkedByAI_idx" ON "tbemergencyreports"("isLinkedByAI");

-- CreateIndex
CREATE INDEX "tbemergencylocations_FK_emergency_idx" ON "tbemergencylocations"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbcalls_FK_emergency_idx" ON "tbcalls"("FK_emergency");

-- CreateIndex
CREATE UNIQUE INDEX "tbemergencyrooms_FK_emergency_key" ON "tbemergencyrooms"("FK_emergency");

-- CreateIndex
CREATE UNIQUE INDEX "tbemergencyrooms_roomCode_key" ON "tbemergencyrooms"("roomCode");

-- CreateIndex
CREATE INDEX "tbemergencyroommembers_FK_room_idx" ON "tbemergencyroommembers"("FK_room");

-- CreateIndex
CREATE INDEX "tbemergencyroommembers_FK_citizen_idx" ON "tbemergencyroommembers"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbemergencyroommembers_FK_institution_idx" ON "tbemergencyroommembers"("FK_institution");

-- CreateIndex
CREATE INDEX "tbemergencyroommembers_FK_unit_idx" ON "tbemergencyroommembers"("FK_unit");

-- CreateIndex
CREATE INDEX "tbchatmessages_FK_room_idx" ON "tbchatmessages"("FK_room");

-- CreateIndex
CREATE INDEX "tbchatmessages_FK_citizen_idx" ON "tbchatmessages"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbchatmessages_FK_user_idx" ON "tbchatmessages"("FK_user");

-- CreateIndex
CREATE INDEX "tbchatmessages_FK_institution_idx" ON "tbchatmessages"("FK_institution");

-- CreateIndex
CREATE INDEX "tbchatmessages_FK_unit_idx" ON "tbchatmessages"("FK_unit");

-- CreateIndex
CREATE INDEX "tbunitlocations_FK_unit_idx" ON "tbunitlocations"("FK_unit");

-- CreateIndex
CREATE INDEX "tbunitlocations_createdAt_idx" ON "tbunitlocations"("createdAt");

-- CreateIndex
CREATE INDEX "tbevidences_FK_emergency_idx" ON "tbevidences"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbevidences_FK_citizen_idx" ON "tbevidences"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbevidences_FK_user_idx" ON "tbevidences"("FK_user");

-- CreateIndex
CREATE INDEX "tbemergencyviews_FK_emergency_idx" ON "tbemergencyviews"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyviews_FK_citizen_idx" ON "tbemergencyviews"("FK_citizen");

-- CreateIndex
CREATE UNIQUE INDEX "tbemergencyviews_FK_emergency_FK_citizen_key" ON "tbemergencyviews"("FK_emergency", "FK_citizen");

-- CreateIndex
CREATE INDEX "tbemergencylikes_FK_emergency_idx" ON "tbemergencylikes"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencylikes_FK_citizen_idx" ON "tbemergencylikes"("FK_citizen");

-- CreateIndex
CREATE UNIQUE INDEX "tbemergencylikes_FK_emergency_FK_citizen_key" ON "tbemergencylikes"("FK_emergency", "FK_citizen");

-- CreateIndex
CREATE INDEX "tbaianalyses_FK_emergency_idx" ON "tbaianalyses"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyrequirements_FK_emergency_idx" ON "tbemergencyrequirements"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyrequirements_FK_resourceType_idx" ON "tbemergencyrequirements"("FK_resourceType");

-- CreateIndex
CREATE INDEX "tbemergencyassignments_FK_emergency_idx" ON "tbemergencyassignments"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyassignments_FK_institution_idx" ON "tbemergencyassignments"("FK_institution");

-- CreateIndex
CREATE INDEX "tbemergencyassignments_FK_subinstitution_idx" ON "tbemergencyassignments"("FK_subinstitution");

-- CreateIndex
CREATE INDEX "tbemergencyassignments_FK_unit_idx" ON "tbemergencyassignments"("FK_unit");

-- CreateIndex
CREATE INDEX "tbassignmenttracking_FK_assignment_idx" ON "tbassignmenttracking"("FK_assignment");

-- CreateIndex
CREATE INDEX "tbassignmenttracking_FK_unit_idx" ON "tbassignmenttracking"("FK_unit");

-- CreateIndex
CREATE INDEX "tbassignmenttracking_createdAt_idx" ON "tbassignmenttracking"("createdAt");

-- CreateIndex
CREATE INDEX "tbemergencystatushistory_FK_emergency_idx" ON "tbemergencystatushistory"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencystatushistory_FK_user_idx" ON "tbemergencystatushistory"("FK_user");

-- CreateIndex
CREATE INDEX "tbemergencyprogressreports_FK_emergency_idx" ON "tbemergencyprogressreports"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyprogressreports_FK_institution_idx" ON "tbemergencyprogressreports"("FK_institution");

-- CreateIndex
CREATE INDEX "tbemergencyprogressreports_FK_user_idx" ON "tbemergencyprogressreports"("FK_user");

-- CreateIndex
CREATE INDEX "tbnotifications_FK_citizen_idx" ON "tbnotifications"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbnotifications_FK_user_idx" ON "tbnotifications"("FK_user");

-- CreateIndex
CREATE INDEX "tbnotifications_FK_emergency_idx" ON "tbnotifications"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencydestinations_FK_emergency_idx" ON "tbemergencydestinations"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencydestinations_FK_institution_idx" ON "tbemergencydestinations"("FK_institution");

-- AddForeignKey
ALTER TABLE "tbinstitutions" ADD CONSTRAINT "tbinstitutions_FK_institutionType_fkey" FOREIGN KEY ("FK_institutionType") REFERENCES "tbinstitutiontypes"("PK_institutionType") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbsubinstitutions" ADD CONSTRAINT "tbsubinstitutions_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions"("PK_institution") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbusers" ADD CONSTRAINT "tbusers_FK_privilege_fkey" FOREIGN KEY ("FK_privilege") REFERENCES "tbprivileges"("PK_privilege") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbusers" ADD CONSTRAINT "tbusers_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions"("PK_institution") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbusers" ADD CONSTRAINT "tbusers_FK_subinstitution_fkey" FOREIGN KEY ("FK_subinstitution") REFERENCES "tbsubinstitutions"("PK_subinstitution") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbdevices" ADD CONSTRAINT "tbdevices_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens"("PK_citizen") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbusersdevices" ADD CONSTRAINT "tbusersdevices_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers"("PK_user") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbinstitutionservices" ADD CONSTRAINT "tbinstitutionservices_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions"("PK_institution") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbinstitutionservices" ADD CONSTRAINT "tbinstitutionservices_FK_resourceType_fkey" FOREIGN KEY ("FK_resourceType") REFERENCES "tbresourcetypes"("PK_resourceType") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbunits" ADD CONSTRAINT "tbunits_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions"("PK_institution") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbunits" ADD CONSTRAINT "tbunits_FK_subinstitution_fkey" FOREIGN KEY ("FK_subinstitution") REFERENCES "tbsubinstitutions"("PK_subinstitution") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbunits" ADD CONSTRAINT "tbunits_FK_resourceType_fkey" FOREIGN KEY ("FK_resourceType") REFERENCES "tbresourcetypes"("PK_resourceType") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencies" ADD CONSTRAINT "tbemergencies_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens"("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencies" ADD CONSTRAINT "tbemergencies_FK_emergencyType_fkey" FOREIGN KEY ("FK_emergencyType") REFERENCES "tbemergencytypes"("PK_emergencyType") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencies" ADD CONSTRAINT "tbemergencies_FK_parentEmergency_fkey" FOREIGN KEY ("FK_parentEmergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbaisessions" ADD CONSTRAINT "tbaisessions_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens"("PK_citizen") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbaisessions" ADD CONSTRAINT "tbaisessions_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyreports" ADD CONSTRAINT "tbemergencyreports_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyreports" ADD CONSTRAINT "tbemergencyreports_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens"("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencylocations" ADD CONSTRAINT "tbemergencylocations_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbcalls" ADD CONSTRAINT "tbcalls_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyrooms" ADD CONSTRAINT "tbemergencyrooms_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyroommembers" ADD CONSTRAINT "tbemergencyroommembers_FK_room_fkey" FOREIGN KEY ("FK_room") REFERENCES "tbemergencyrooms"("PK_room") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyroommembers" ADD CONSTRAINT "tbemergencyroommembers_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens"("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyroommembers" ADD CONSTRAINT "tbemergencyroommembers_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers"("PK_user") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyroommembers" ADD CONSTRAINT "tbemergencyroommembers_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions"("PK_institution") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyroommembers" ADD CONSTRAINT "tbemergencyroommembers_FK_unit_fkey" FOREIGN KEY ("FK_unit") REFERENCES "tbunits"("PK_unit") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbchatmessages" ADD CONSTRAINT "tbchatmessages_FK_room_fkey" FOREIGN KEY ("FK_room") REFERENCES "tbemergencyrooms"("PK_room") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbchatmessages" ADD CONSTRAINT "tbchatmessages_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens"("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbchatmessages" ADD CONSTRAINT "tbchatmessages_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers"("PK_user") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbchatmessages" ADD CONSTRAINT "tbchatmessages_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions"("PK_institution") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbchatmessages" ADD CONSTRAINT "tbchatmessages_FK_unit_fkey" FOREIGN KEY ("FK_unit") REFERENCES "tbunits"("PK_unit") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbunitlocations" ADD CONSTRAINT "tbunitlocations_FK_unit_fkey" FOREIGN KEY ("FK_unit") REFERENCES "tbunits"("PK_unit") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbevidences" ADD CONSTRAINT "tbevidences_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbevidences" ADD CONSTRAINT "tbevidences_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens"("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbevidences" ADD CONSTRAINT "tbevidences_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers"("PK_user") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyviews" ADD CONSTRAINT "tbemergencyviews_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyviews" ADD CONSTRAINT "tbemergencyviews_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens"("PK_citizen") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencylikes" ADD CONSTRAINT "tbemergencylikes_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencylikes" ADD CONSTRAINT "tbemergencylikes_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens"("PK_citizen") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbaianalyses" ADD CONSTRAINT "tbaianalyses_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyrequirements" ADD CONSTRAINT "tbemergencyrequirements_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyrequirements" ADD CONSTRAINT "tbemergencyrequirements_FK_resourceType_fkey" FOREIGN KEY ("FK_resourceType") REFERENCES "tbresourcetypes"("PK_resourceType") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyassignments" ADD CONSTRAINT "tbemergencyassignments_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyassignments" ADD CONSTRAINT "tbemergencyassignments_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions"("PK_institution") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyassignments" ADD CONSTRAINT "tbemergencyassignments_FK_subinstitution_fkey" FOREIGN KEY ("FK_subinstitution") REFERENCES "tbsubinstitutions"("PK_subinstitution") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyassignments" ADD CONSTRAINT "tbemergencyassignments_FK_unit_fkey" FOREIGN KEY ("FK_unit") REFERENCES "tbunits"("PK_unit") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbassignmenttracking" ADD CONSTRAINT "tbassignmenttracking_FK_assignment_fkey" FOREIGN KEY ("FK_assignment") REFERENCES "tbemergencyassignments"("PK_assignment") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbassignmenttracking" ADD CONSTRAINT "tbassignmenttracking_FK_unit_fkey" FOREIGN KEY ("FK_unit") REFERENCES "tbunits"("PK_unit") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencystatushistory" ADD CONSTRAINT "tbemergencystatushistory_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencystatushistory" ADD CONSTRAINT "tbemergencystatushistory_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers"("PK_user") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyprogressreports" ADD CONSTRAINT "tbemergencyprogressreports_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyprogressreports" ADD CONSTRAINT "tbemergencyprogressreports_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions"("PK_institution") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencyprogressreports" ADD CONSTRAINT "tbemergencyprogressreports_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers"("PK_user") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbnotifications" ADD CONSTRAINT "tbnotifications_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens"("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbnotifications" ADD CONSTRAINT "tbnotifications_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers"("PK_user") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbnotifications" ADD CONSTRAINT "tbnotifications_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencydestinations" ADD CONSTRAINT "tbemergencydestinations_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies"("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbemergencydestinations" ADD CONSTRAINT "tbemergencydestinations_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions"("PK_institution") ON DELETE SET NULL ON UPDATE CASCADE;
