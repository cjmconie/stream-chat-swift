//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(MemberDTO)
class MemberDTO: NSManagedObject {
    // Because we need to have a unique identifier of a member in the db, we use the combination of the related
    // user' id and the channel the member belongs to.
    @NSManaged fileprivate var id: String
    
    var cid: ChannelId {
        try! .init(cid: String(id.dropLast(user.id.count)))
    }
    
    // This value is optional only temprorary until this is fixed https://getstream.slack.com/archives/CE5N802GP/p1592925726015900
    @NSManaged var channelRoleRaw: String?
    @NSManaged var memberCreatedAt: Date
    @NSManaged var memberUpdatedAt: Date
    
    //  @NSManaged var invitedAcceptedAt: Date?
    //  @NSManaged var invitedRejectedAt: Date?
    //  @NSManaged var isInvited: Bool
    
    // MARK: - Relationships
    
    @NSManaged var user: UserDTO
    
    private static func createId(userId: String, channeldId: ChannelId) -> String {
        channeldId.rawValue + userId
    }
}

// MARK: - Fetch requests

extension MemberDTO {
    /// Returns a fetch request for the dto with the provided `userId`.
    static func member(_ userId: UserId, in cid: ChannelId) -> NSFetchRequest<MemberDTO> {
        let request = NSFetchRequest<MemberDTO>(entityName: MemberDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MemberDTO.memberCreatedAt, ascending: false)]
        request.predicate = NSPredicate(format: "id == %@", Self.createId(userId: userId, channeldId: cid))
        return request
    }
    
    /// Returns a fetch request for the DTOs matching the provided `query`.
    static func members<ExtraData: UserExtraData>(matching query: ChannelMemberListQuery<ExtraData>) -> NSFetchRequest<MemberDTO> {
        let request = NSFetchRequest<MemberDTO>(entityName: MemberDTO.entityName)
        request.predicate = NSPredicate(format: "ANY queries.queryHash == %@", query.queryHash)
        request.sortDescriptors = query.sortDescriptors
        return request
    }
}

extension MemberDTO {
    static func load(id: String, channelId: ChannelId, context: NSManagedObjectContext) -> MemberDTO? {
        let memberId = MemberDTO.createId(userId: id, channeldId: channelId)
        let request = NSFetchRequest<MemberDTO>(entityName: MemberDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", memberId)
        return try? context.fetch(request).first
    }
    
    /// If a User with the given id exists in the context, fetches and returns it. Otherwise create a new
    /// `UserDTO` with the given id.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch/create `UserDTO`
    ///
    static func loadOrCreate(id: String, channelId: ChannelId, context: NSManagedObjectContext) -> MemberDTO {
        if let existing = Self.load(id: id, channelId: channelId, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! MemberDTO
        new.id = Self.createId(userId: id, channeldId: channelId)
        return new
    }
}

extension NSManagedObjectContext {
    func saveMember<ExtraData: UserExtraData>(
        payload: MemberPayload<ExtraData>,
        channelId: ChannelId,
        query: ChannelMemberListQuery<ExtraData>?
    ) throws -> MemberDTO {
        let dto = MemberDTO.loadOrCreate(id: payload.user.id, channelId: channelId, context: self)
        
        // Save user-part of member first
        dto.user = try saveUser(payload: payload.user)
        
        // Save member specific data
        if let role = payload.role {
            dto.channelRoleRaw = role.rawValue
        }
        
        dto.memberCreatedAt = payload.createdAt
        dto.memberUpdatedAt = payload.updatedAt
        
        if let query = query {
            let queryDTO = try saveQuery(query)
            queryDTO.members.insert(dto)
        }
        
        return dto
    }
    
    func member(userId: UserId, cid: ChannelId) -> MemberDTO? {
        MemberDTO.load(id: userId, channelId: cid, context: self)
    }
}

extension MemberDTO {
    func asModel<ExtraData: UserExtraData>() -> _ChatChannelMember<ExtraData> { .create(fromDTO: self) }
}

extension _ChatChannelMember {
    fileprivate static func create(fromDTO dto: MemberDTO) -> _ChatChannelMember {
        let role = dto.channelRoleRaw.flatMap { MemberRole(rawValue: $0) } ?? .member
        
        return _ChatChannelMember(
            cid: dto.cid,
            user: dto.user.asModel(),
            memberRole: role,
            memberCreatedAt: dto.memberCreatedAt,
            memberUpdatedAt: dto.memberUpdatedAt,
            isInvited: false,
            inviteAcceptedAt: nil,
            inviteRejectedAt: nil
        )
    }
}

private extension ChannelMemberListQuery {
    var sortDescriptors: [NSSortDescriptor] {
        let sortDescriptors = sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        return sortDescriptors.isEmpty ? [ChannelMemberListSortingKey.defaultSortDescriptor] : sortDescriptors
    }
}
