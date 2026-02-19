import '../models/user.dart';
import '../models/task.dart';
import '../models/offer.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import '../models/payment_method.dart';
import '../models/payment_transaction.dart';
import '../models/notification_settings.dart';
import '../models/question.dart';
import '../models/category.dart';
import '../models/search_history.dart';
import '../models/portfolio_item.dart';
import '../models/review.dart';
import 'package:flutter/material.dart';

class MockDataService {
  // Mock Users - Single Source of Truth
  static final List<User> mockUsers = [
    // User 1: John Doe - Current logged-in user, experienced tasker
    User(
      id: '1',
      email: 'john.doe@example.com',
      name: 'John Doe',
      phone: '+61 412 345 678',
      profileImage: 'https://i.pravatar.cc/150?img=11',
      bio: 'Experienced handyman with over 5 years of experience in furniture assembly and home repairs.',
      skills: ['Furniture Assembly', 'Painting', 'Gardening'],
      rating: 5.0,
      totalReviews: 340,
      isVerified: true,
      verificationType: 'Identity Verified',
      memberSince: DateTime.now().subtract(const Duration(days: 730)),
      portfolio: [
        const PortfolioItem(
          url: 'https://picsum.photos/id/1/400/300',
          type: 'image',
          title: 'IKEA Assembly',
          description: 'Assembled a full bedroom set including PAX wardrobe.',
        ),
      ],
      ratingCategories: {
        'Communication': 5.0,
        'Punctuality': 5.0,
        'Eye for detail': 5.0,
        'Efficiency': 5.0,
      },
      reviews: [
        Review(
          id: 'r1',
          reviewerId: 'u_cassie',
          reviewerName: 'Cassie S.',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=5',
          rating: 5.0,
          comment: 'Friendly, fast and professional - highly recommend',
          date: DateTime.now().subtract(const Duration(days: 2)),
          taskTitle: 'Wardrobe assembly',
        ),
        Review(
          id: 'r2',
          reviewerId: 'u_deborah',
          reviewerName: 'Deborah D.',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=9',
          rating: 5.0,
          comment: 'he was brilliant quick, professional. highly recommend',
          date: DateTime.now().subtract(const Duration(days: 2)),
          taskTitle: 'Wardrobe to be put together',
        ),
        Review(
          id: 'r3',
          reviewerId: 'u_dmitry',
          reviewerName: 'Dmitry K.',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=12',
          rating: 5.0,
          comment: 'Great quick work, nice communication!',
          date: DateTime.now().subtract(const Duration(days: 7)),
          taskTitle: 'To Assemble an IKEA Study Table with Shelves',
        ),
        Review(
          id: 'r4',
          reviewerId: 'u_vani',
          reviewerName: 'Vani G.',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=3',
          rating: 5.0,
          comment: 'Kieran was super effective and helpful, all done in an hour and would highly recommend again!',
          date: DateTime.now().subtract(const Duration(days: 7)),
          taskTitle: 'Build Ikea cupboard',
        ),
        Review(
          id: 'r5',
          reviewerId: 'u_marie',
          reviewerName: 'Marie J.',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=1',
          rating: 5.0,
          comment: 'Brought covers for his footwear. More than pleased with the job. Keiran was professional, focused, good work ethic, respectful and applied himself professionally to the task. Tidied up after the job. Would recommend 1000000%.',
          date: DateTime.now().subtract(const Duration(days: 14)),
          taskTitle: 'A double "Corona" wardrobe assembled',
          images: ['https://picsum.photos/id/1/400/300'], // Placeholder for the wardrobe image
        ),
        Review(
          id: 'r6',
          reviewerId: 'u_jordan',
          reviewerName: 'Jordan E.',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=8',
          rating: 5.0,
          comment: 'Kieran stayed in communication with me and arrived on time, ready to start. He was really friendly and got the task done quickly and to a high standard. Highly recommend!',
          date: DateTime.now().subtract(const Duration(days: 14)),
          taskTitle: 'Help putting up curtains and some shelves',
        ),
      ],
    ),
    
    // User 2: Sarah Smith - Task poster
    User(
      id: '2',
      email: 'sarah.smith@example.com',
      name: 'Sarah Smith',
      phone: '+61 423 456 789',
      profileImage: 'https://i.pravatar.cc/150?img=5',
      bio: 'Love helping out with pet care and gardening. Very reliable!',
      skills: ['Pet Care', 'Gardening'],
      rating: 4.9,
      totalReviews: 45,
      isVerified: true,
      verificationType: 'ID + Phone',
      memberSince: DateTime.now().subtract(const Duration(days: 365)),
      reviews: [
        Review(
          id: 'r3',
          reviewerId: '1',
          reviewerName: 'John Doe',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=11',
          rating: 5.0,
          comment: 'Sarah took great care of my dog while I was away. Highly recommend!',
          date: DateTime.now().subtract(const Duration(days: 20)),
          taskTitle: 'Pet Sitting',
        ),
        Review(
          id: 'r4',
          reviewerId: '8',
          reviewerName: 'Emily Jones',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=9',
          rating: 4.8,
          comment: 'Very professional and caring with pets.',
          date: DateTime.now().subtract(const Duration(days: 45)),
          taskTitle: 'Dog Walking',
        ),
      ],
    ),
    
    // User 3: Mohammed A. - Top expert tasker
    User(
      id: '3',
      email: 'mohammed.a@email.com',
      name: 'Mohammed A.',
      phone: '+61 434 567 890',
      profileImage: 'https://i.pravatar.cc/150?img=33',
      bio: 'Professional tradesman with team. We have correct equipment and tools for any job.',
      skills: ['All Trades', 'Team Available'],
      rating: 5.0,
      totalReviews: 949,
      isVerified: true,
      verificationType: 'ID + Business License',
      memberSince: DateTime.now().subtract(const Duration(days: 1825)),
      reviews: [
        Review(
          id: 'r5',
          reviewerId: '2',
          reviewerName: 'Sarah Smith',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=5',
          rating: 5.0,
          comment: 'Outstanding work! Mohammed and his team were professional and completed everything perfectly.',
          date: DateTime.now().subtract(const Duration(days: 7)),
          taskTitle: 'Home Renovation',
        ),
        Review(
          id: 'r6',
          reviewerId: '8',
          reviewerName: 'Emily Jones',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=9',
          rating: 5.0,
          comment: 'Best tasker I\'ve worked with. Attention to detail is exceptional.',
          date: DateTime.now().subtract(const Duration(days: 15)),
          taskTitle: 'Bathroom Tiling',
        ),
      ],
    ),
    
    // User 4: Abdel K. - Experienced verified tasker
    User(
      id: '4',
      email: 'abdel.k@email.com',
      name: 'Abdel K.',
      phone: '+61 445 678 901',
      profileImage: 'https://i.pravatar.cc/150?img=15',
      bio: 'Experienced in various home improvement tasks. Quality guaranteed.',
      skills: ['Carpentry', 'Plumbing', 'General Repairs'],
      rating: 4.9,
      totalReviews: 36,
      isVerified: true,
      verificationType: 'ID Verified',
      memberSince: DateTime.now().subtract(const Duration(days: 550)),
      reviews: [
        Review(
          id: 'r7',
          reviewerId: '1',
          reviewerName: 'John Doe',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=11',
          rating: 5.0,
          comment: 'Abdel did an excellent job fixing my leaking tap. Very professional.',
          date: DateTime.now().subtract(const Duration(days: 10)),
          taskTitle: 'Plumbing Repair',
        ),
      ],
    ),
    
    // User 5: Reiss H. - NEW user, just joined
    User(
      id: '5',
      email: 'reiss.h@email.com',
      name: 'Reiss H.',
      phone: '+61 456 789 012',
      profileImage: 'https://i.pravatar.cc/150?img=51',
      bio: 'New to Airmass Xpress but have lots of experience. Looking forward to helping you!',
      skills: ['Moving', 'Delivery'],
      rating: 0.0,
      totalReviews: 0,
      isVerified: false,
      memberSince: DateTime.now().subtract(const Duration(days: 5)),
      reviews: [], // New user - no reviews yet
    ),
    
    // User 6: Lisa M. - Regular tasker, not verified
    User(
      id: '6',
      email: 'lisa.m@email.com',
      name: 'Lisa M.',
      phone: '+61 467 890 123',
      profileImage: 'https://i.pravatar.cc/150?img=45',
      bio: 'Friendly and reliable. Happy to help with various tasks.',
      skills: ['Cleaning', 'Organization'],
      rating: 4.6,
      totalReviews: 12,
      isVerified: false,
      memberSince: DateTime.now().subtract(const Duration(days: 180)),
      reviews: [
        Review(
          id: 'r8',
          reviewerId: '2',
          reviewerName: 'Sarah Smith',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=5',
          rating: 4.5,
          comment: 'Lisa did a good cleaning job. Would hire again.',
          date: DateTime.now().subtract(const Duration(days: 30)),
          taskTitle: 'House Cleaning',
        ),
      ],
    ),
    
    // User 7: James T. - NEW user, just joined
    User(
      id: '7',
      email: 'james.t@email.com',
      name: 'James T.',
      phone: '+61 478 901 234',
      profileImage: 'https://i.pravatar.cc/150?img=52',
      bio: 'Eager to help! Just joined Airmass Xpress and ready to take on tasks.',
      skills: ['General Labor', 'Moving'],
      rating: 0.0,
      totalReviews: 0,
      isVerified: false,
      memberSince: DateTime.now().subtract(const Duration(days: 2)),
      reviews: [], // New user - no reviews yet
    ),
    
    // User 8: Emily Jones - Task poster with some tasker experience
    User(
      id: '8',
      email: 'emily.jones@email.com',
      name: 'Emily Jones',
      phone: '+61 489 012 345',
      profileImage: 'https://i.pravatar.cc/150?img=9',
      bio: 'Professional photographer and event coordinator.',
      skills: ['Photography', 'Event Planning'],
      rating: 4.7,
      totalReviews: 15,
      isVerified: false,
      memberSince: DateTime.now().subtract(const Duration(days: 200)),
      reviews: [
        Review(
          id: 'r9',
          reviewerId: '3',
          reviewerName: 'Mohammed A.',
          reviewerAvatar: 'https://i.pravatar.cc/150?img=33',
          rating: 5.0,
          comment: 'Emily did an amazing job photographing our event. Very professional!',
          date: DateTime.now().subtract(const Duration(days: 25)),
          taskTitle: 'Event Photography',
        ),
      ],
    ),
    
    // User 9: Tollad C. - Poster with no activity (Empty State Test)
    User(
      id: '9',
      email: 'tollad.c@email.com',
      name: 'tollad c.',
      phone: '+61 490 123 456',
      profileImage: null, // No image as per screenshot
      bio: null,
      skills: [],
      rating: 0.0,
      totalReviews: 0,
      isVerified: true,
      verificationType: 'Mobile Verified',
      memberSince: DateTime.now().subtract(const Duration(hours: 12)), // "Online less than a day ago"
      reviews: [],
      userType: 'poster',
    ),
  ];

  static User getUserById(String id) {
    return mockUsers.firstWhere(
      (user) => user.id == id,
      orElse: () => User(
        id: id,
        email: '',
        name: 'Unknown User',
        rating: 0,
        totalReviews: 0,
        memberSince: DateTime.now(),
      ),
    );
  }

  // Mock Tasks
  static final List<Task> mockTasks = [
    Task(
      id: 't1',
      posterId: '2',
      title: 'Help moving furniture to new apartment',
      description: 'Need help moving a 3-seater sofa, dining table, and 2 beds from my current place to my new apartment about 5km away. Access via stairs (no lift). Need 2 people with a van.',
      category: 'Removalists',
      locationAddress: 'Sydney CBD, NSW',
      locationLat: -33.8688,
      locationLng: 151.2093,
      photos: [
        'https://images.unsplash.com/photo-1556909212-d5b604d0c90d?w=800',
        'https://images.unsplash.com/photo-1550581190-9c1c48d21d6c?w=800',
      ],
      budget: 250.0,
      deadline: DateTime.now().add(const Duration(days: 3)),
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      posterName: 'Sarah Smith',
      posterImage: 'https://i.pravatar.cc/150?img=5',
      posterVerified: true,
      posterRating: 4.9,
      offersCount: 3,
      views: 12,
    ),
    Task(
      id: 't2',
      posterId: 'u3',
      title: 'Fix my washing machine',
      description: 'My Samsung washing machine is not draining water. It stops mid-cycle and shows an error code. Need someone experienced with appliance repair to fix it.',
      category: 'Repairs',
      locationAddress: 'Bondi Beach, NSW',
      locationLat: -33.8915,
      locationLng: 151.2767,
      photos: [
        'https://images.unsplash.com/photo-1626806775351-538af710a40b?auto=format&fit=crop&q=80&w=800',
      ],
      budget: 120.0,
      deadline: DateTime.now().add(const Duration(days: 2)),
      status: 'Open',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      posterName: 'Sarah J.',
      posterImage: 'https://i.pravatar.cc/150?u=3',
      posterVerified: true,
      posterRating: 4.9,
      offersCount: 2,
      views: 8,
    ),
    Task(
      id: 't3',
      posterId: 'u4',
      title: 'Help moving furniture',
      description: 'Need help moving a sofa and a fridge to the second floor. No elevator, just stairs. Should take about an hour.',
      category: 'Removals',
      locationAddress: 'Surry Hills, NSW',
      locationLat: -33.8861,
      locationLng: 151.2111,
      photos: [],
      budget: 80.0,
      deadline: DateTime.now().add(const Duration(days: 1)),
      status: 'Open',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      posterName: 'Mike T.',
      posterImage: 'https://i.pravatar.cc/150?u=4',
      posterVerified: false,
      posterRating: 0.0,
      offersCount: 0,
      views: 3,
    ),
    Task(
      id: 't4',
      posterId: 'u5',
      title: 'Gardening and weeding',
      description: 'Small backyard needs weeding and lawn mowing. Green bin provided. Bring your own tools please.',
      category: 'Gardening',
      locationAddress: 'Newtown, NSW',
      locationLat: -33.8970,
      locationLng: 151.1793,
      photos: [
        'https://images.unsplash.com/photo-1558904541-efa843a96f01?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1592417817098-8fd3d9eb14a5?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&q=80&w=800',
      ],
      budget: 100.0,
      deadline: DateTime.now().add(const Duration(days: 3)),
      status: 'Open',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      posterName: 'Emma W.',
      posterImage: 'https://i.pravatar.cc/150?u=5',
      posterVerified: true,
      posterRating: 4.7,
      offersCount: 3,
      views: 24,
    ),
    Task(
      id: 't5',
      posterId: '5',
      title: 'Assemble IKEA Wardrobe',
      description: 'PAX wardrobe assembly required. 2m wide, sliding doors. I have all the tools if needed.',
      category: 'Assembly',
      locationAddress: 'Chatswood, NSW',
      locationLat: -33.7969,
      locationLng: 151.1835,
      photos: [],
      budget: 180.0,
      deadline: DateTime.now().add(const Duration(days: 4)),
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      posterName: 'David Wilson',
      posterImage: 'https://i.pravatar.cc/150?img=15',
      posterVerified: true,
      posterRating: 4.9,
      offersCount: 0,
      views: 15,
    ),
    Task(
      id: 't6',
      posterId: '1',
      title: 'Interior wall painting - 2 bedrooms',
      description: 'Need 2 bedrooms painted (walls only, no ceiling). Rooms are empty and ready to paint. Paint and supplies already purchased. Just need labor.',
      category: 'Painting',
      locationAddress: 'Manly, NSW',
      locationLat: -33.7969,
      locationLng: 151.2840,
      photos: [
        'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=800',
        'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=800',
      ],
      budget: 600.0,
      deadline: DateTime.now().add(const Duration(days: 7)),
      status: 'posted',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      posterName: 'John Doe',
      posterImage: 'https://i.pravatar.cc/150?img=11',
      posterVerified: true,
      posterRating: 4.8,
      offersCount: 2,
      views: 15,
    ),
    // Additional John Doe tasks with different statuses
    Task(
      id: 't7',
      posterId: '1',
      title: 'Deep clean my apartment',
      description: '2 bedroom apartment needs deep cleaning including kitchen, bathroom, and all rooms. All cleaning supplies provided.',
      category: 'Cleaning',
      locationAddress: 'Bondi, NSW',
      locationLat: -33.8915,
      locationLng: 151.2767,
      photos: [],
      budget: 180.0,
      deadline: DateTime.now().add(const Duration(days: 2)),
      status: 'assigned',
      assignedTo: '2',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      posterName: 'John Doe',
      posterImage: 'https://i.pravatar.cc/150?img=11',
      posterVerified: true,
      posterRating: 4.8,
      offersCount: 4,
      views: 28,
    ),
    Task(
      id: 't8',
      posterId: '1',
      title: 'Assemble IKEA furniture',
      description: 'Need help assembling IKEA Billy bookshelf and Malm dresser. All parts included.',
      category: 'Assembly',
      locationAddress: 'Surry Hills, NSW',
      locationLat: -33.8861,
      locationLng: 151.2111,
      photos: [
        'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800',
      ],
      budget: 120.0,
      deadline: DateTime.now().subtract(const Duration(days: 5)),
      status: 'completed',
      assignedTo: '3',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      posterName: 'John Doe',
      posterImage: 'https://i.pravatar.cc/150?img=11',
      posterVerified: true,
      posterRating: 4.8,
      offersCount: 5,
      views: 35,
    ),
    Task(
      id: 't9',
      posterId: '1',
      title: 'Paint inside walls of my bedroom',
      description: 'I need someone to paint the bedroom of my son. It\'s an average size room',
      category: 'Painting',
      locationAddress: 'Soho, Greater London, W1D 6, England',
      locationLat: -33.8688,
      locationLng: 151.2093,
      photos: [],
      budget: 200.0,
      deadline: DateTime.now().add(const Duration(days: 1)),
      status: 'cancelled',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      posterName: 'John Doe',
      posterImage: 'https://i.pravatar.cc/150?img=11',
      posterVerified: true,
      posterRating: 4.8,
      offersCount: 1,
      views: 18,
    ),
    Task(
      id: 't10',
      posterId: '1',
      title: 'Garden maintenance and lawn mowing',
      description: 'Regular garden maintenance needed - lawn mowing, hedge trimming, weeding. Weekly service preferred.',
      category: 'Gardening',
      locationAddress: 'Manly, NSW',
      locationLat: -33.7969,
      locationLng: 151.2840,
      photos: [
        'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=800',
      ],
      budget: 95.0,
      deadline: DateTime.now().add(const Duration(days: 5)),
      status: 'posted',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      posterName: 'John Doe',
      posterImage: 'https://i.pravatar.cc/150?img=11',
      posterVerified: true,
      posterRating: 4.8,
      offersCount: 3,
      views: 22,
    ),
  ];

  // Mock Offers - Properly linked to users and tasks
  static final List<Offer> mockOffers = [
    // Offers for Task t1 (Sarah's furniture moving task)
    // Offer from Reiss H. - NEW user
    Offer(
      id: 'o1',
      taskId: 't1',
      taskerId: '5',
      amount: 180.0,
      message: 'Hi Patrick, I am available to assist you with this job. I am new to the app, but rest assured you will be delighted with my service. Will take pleasure in making your life easier. Local to you.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      taskerName: 'Reiss H.',
      taskerImage: 'https://i.pravatar.cc/150?img=51',
      taskerVerified: false,
      isNew: true,
      availability: 'Today · Tomorrow',
    ),
    // Offer from Abdel K. - Verified with completion rate
    Offer(
      id: 'o2',
      taskId: 't1',
      taskerId: '4',
      amount: 210.0,
      message: 'I\'d be happy to assist with this task. My work is always carried out with attention to detail and professionalism to ensure everything is complete to the highest standards.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      taskerName: 'Abdel K.',
      taskerImage: 'https://i.pravatar.cc/150?img=15',
      taskerVerified: true,
      taskerRating: 4.9,
      reviewCount: 36,
      completionRate: 75,
      rebookCount: 2,
      availability: 'This weekend',
    ),
    // Offer from Mohammed A. - Top tasker
    Offer(
      id: 'o3',
      taskId: 't1',
      taskerId: '3',
      amount: 195.0,
      message: 'Hi, my name is Mo, I am available and happy to complete this task with my team we have the correct equipment and tools. You\'re welcome to view my profile to see my completion rate.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(minutes: 36)),
      taskerName: 'Mohammed A.',
      taskerImage: 'https://i.pravatar.cc/150?img=33',
      taskerVerified: true,
      taskerRating: 5.0,
      reviewCount: 949,
      completionRate: 95,
      rebookCount: 5,
    ),
    
    // Offers for Task t2 (John's plumbing task)
    // Offer from Lisa M. - Regular tasker
    Offer(
      id: 'o4',
      taskId: 't2',
      taskerId: '6',
      amount: 120.0,
      message: 'I can help you with this. I have experience with plumbing repairs and all the necessary tools.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      taskerName: 'Lisa M.',
      taskerImage: 'https://i.pravatar.cc/150?img=45',
      taskerVerified: false,
      taskerRating: 4.6,
      reviewCount: 12,
    ),
    // Offer from James T. - NEW user
    Offer(
      id: 'o5',
      taskId: 't2',
      taskerId: '7',
      amount: 95.0,
      message: 'Happy to help! I\'m new to Airmass Xpress but have lots of plumbing experience. Looking forward to building my reputation here.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      taskerName: 'James T.',
      taskerImage: 'https://i.pravatar.cc/150?img=52',
      taskerVerified: false,
      isNew: true, // New user
    ),
    
    // Offers for Task t4 (Emily's wedding photography)
    // Offer from John Doe
    Offer(
      id: 'o6',
      taskId: 't4',
      taskerId: '1',
      amount: 750.0,
      message: 'I\'d love to photograph your wedding! I have experience with events and will provide high-quality digital files.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      taskerName: 'John Doe',
      taskerImage: 'https://i.pravatar.cc/150?img=11',
      taskerVerified: true,
      taskerRating: 4.8,
      reviewCount: 124,
    ),
    // Offer from Sarah Smith
    Offer(
      id: 'o7',
      taskId: 't4',
      taskerId: '2',
      amount: 800.0,
      message: 'I specialize in wedding photography and would be honored to capture your special day. Professional equipment and editing included.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      taskerName: 'Sarah Smith',
      taskerImage: 'https://i.pravatar.cc/150?img=5',
      taskerVerified: true,
      taskerRating: 4.9,
      reviewCount: 45,
    ),
    // Offer from Abdel K.
    Offer(
      id: 'o8',
      taskId: 't4',
      taskerId: '4',
      amount: 820.0,
      message: 'Professional wedding photography service. I ensure every moment is captured beautifully with high-res digital delivery.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      taskerName: 'Abdel K.',
      taskerImage: 'https://i.pravatar.cc/150?img=15',
      taskerVerified: true,
      taskerRating: 4.9,
      reviewCount: 36,
      completionRate: 75,
    ),
    
    // Offers for Task t6 (John's painting task)
    // Offer from Mohammed A.
    Offer(
      id: 'o9',
      taskId: 't6',
      taskerId: '3',
      amount: 580.0,
      message: 'My team and I can handle your painting job professionally. We have all equipment and will complete it to the highest standard.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      taskerName: 'Mohammed A.',
      taskerImage: 'https://i.pravatar.cc/150?img=33',
      taskerVerified: true,
      taskerRating: 5.0,
      reviewCount: 949,
      completionRate: 95,
      rebookCount: 5,
    ),
    // Offer from Lisa M.
    Offer(
      id: 'o10',
      taskId: 't6',
      taskerId: '6',
      amount: 550.0,
      message: 'I can paint your bedrooms professionally. Quality work guaranteed with attention to detail.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      taskerName: 'Lisa M.',
      taskerImage: 'https://i.pravatar.cc/150?img=45',
      taskerVerified: false,
      taskerRating: 4.6,
      reviewCount: 12,
    ),
  ];

  // Mock Conversations
  static final List<Conversation> mockConversations = [
    Conversation(
      id: 'conv1',
      taskId: 't1',
      otherUserId: '3',
      otherUserName: 'Michael Brown',
      otherUserImage: 'https://i.pravatar.cc/150?img=33',
      lastMessage: 'I can help you with the furniture removal',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
      unreadCount: 2,
    ),
    Conversation(
      id: 'conv2',
      taskId: 't2',
      otherUserId: '2',
      otherUserName: 'Sarah Smith',
      otherUserImage: 'https://i.pravatar.cc/150?img=5',
      lastMessage: 'When would you like me to start the cleaning?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
    ),
  ];

  // Mock Messages
  static final List<Message> mockMessages = [
    Message(
      id: 'msg1',
      conversationId: 'conv1',
      senderId: '3',
      receiverId: 'currentUser',
      content: 'Hi! I saw your furniture removal task. I have a van and can help.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      read: true,
    ),
    Message(
      id: 'msg2',
      conversationId: 'conv1',
      senderId: 'currentUser',
      receiverId: '3',
      content: 'Great! When are you available?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
      read: true,
    ),
    Message(
      id: 'msg3',
      conversationId: 'conv1',
      senderId: '3',
      receiverId: 'currentUser',
      content: 'I can help you with the furniture removal',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      read: false,
    ),
    Message(
      id: 'msg4',
      conversationId: 'conv2',
      senderId: '2',
      receiverId: 'currentUser',
      content: 'Hey! I specialize in end-of-lease cleaning',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      read: true,
    ),
    Message(
      id: 'msg5',
      conversationId: 'conv2',
      senderId:  'currentUser',
      receiverId: '2',
      content: 'Perfect! Do you have your own equipment?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      read: true,
    ),
    Message(
      id: 'msg6',
      conversationId: 'conv2',
      senderId: '2',
      receiverId: 'currentUser',
      content: 'When would you like me to start the cleaning?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      read: true,
    ),
  ];

  // Get methods
  // Get methods
  Future<List<Task>> getTasks() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return mockTasks;
  }

  Future<Task?> getTaskById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return mockTasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Offer>> getOffersForTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return mockOffers.where((offer) => offer.taskId == taskId).toList();
  }



  static Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simulate logged in user with ID '1' (John Doe)
    // This allows testing task ownership - most tasks are owned by user '2', so accept won't show
    return mockUsers.first; // ID: '1'
  }

  static Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // Simulate successful login
    return mockUsers.first;
  }

  static Future<User> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // Simulate successful registration
    return User(
      id: 'new_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
      isVerified: false,
      rating: 0.0,
      totalReviews: 0,
    );
  }

  Future<List<Conversation>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return mockConversations;
  }

  Future<List<Message>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return mockMessages
        .where((message) => message.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> sendMessage(Message message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    mockMessages.add(message);
  }

  Future<void> markMessageAsRead(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = mockMessages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      mockMessages[index] = mockMessages[index].copyWith(read: true);
    }
  }

  // Accept an offer - updates task and offer status
  Future<void> acceptOffer(String offerId, String taskId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Find the offer
    final offerIndex = mockOffers.indexWhere((o) => o.id == offerId);
    if (offerIndex == -1) {
      throw Exception('Offer not found');
    }
    
    final offer = mockOffers[offerIndex];
    
    // Create new offer with updated status
    mockOffers[offerIndex] = Offer(
      id: offer.id,
      taskId: offer.taskId,
      taskerId: offer.taskerId,
      amount: offer.amount,
      message: offer.message,
      status: 'accepted', // Changed from 'pending' to 'accepted'
      createdAt: offer.createdAt,
      taskerName: offer.taskerName,
      taskerImage: offer.taskerImage,
      taskerVerified: offer.taskerVerified,
      taskerRating: offer.taskerRating,
      reviewCount: offer.reviewCount,
      completionRate: offer.completionRate,
      rebookCount: offer.rebookCount,
      isNew: offer.isNew,
      availability: offer.availability,
    );
    
    // Update task status to assigned
    final taskIndex = mockTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = mockTasks[taskIndex];
      mockTasks[taskIndex] = Task(
        id: task.id,
        posterId: task.posterId,
        title: task.title,
        description: task.description,
        category: task.category,
        locationAddress: task.locationAddress,
        locationLat: task.locationLat,
        locationLng: task.locationLng,
        photos: task.photos,
        budget: task.budget,
        deadline: task.deadline,
        status: 'assigned', // Changed to assigned
        assignedTo: offer.taskerId, // Set who it's assigned to
        createdAt: task.createdAt,
        posterName: task.posterName,
        posterImage: task.posterImage,
        posterVerified: task.posterVerified,
        posterRating: task.posterRating,
        offersCount: task.offersCount,
        views: task.views,
        dateType: task.dateType,
        hasSpecificTime: task.hasSpecificTime,
        timeOfDay: task.timeOfDay,
      );
    }
    
    // TODO: Create notification for the tasker
    // This should be implemented when notification system is ready
  }

  // Profile Data
  static UserProfile mockUserProfile = UserProfile(
    id: '1',
    name: 'John Doe',
    email: 'john.doe@email.com',
    phone: '+61 412 345 678',
    profileImage: 'https://i.pravatar.cc/150?img=12',
    bio: 'Professional handyman with 10+ years experience. I take pride in my work and always deliver high-quality results.',
    skills: ['Plumbing', 'Electrical', 'Carpentry', 'Painting'],
    rating: 4.8,
    totalReviews: 127,
    completedTasks: 145,
    completionRate: 0.95,
    isVerified: true,
    verificationType: 'ID + Phone',
    jobTitle: 'Licensed Tradesperson',
    company: 'Doe Services Pty Ltd',
    address: '123 Main Street',
    city: 'Sydney',
    country: 'Australia',
    postcode: '2000',
    dateOfBirth: DateTime(1985, 6, 15),
  );

  static List<PaymentMethod> mockPaymentMethods = [
    PaymentMethod(
      id: 'pm1',
      type: PaymentType.card,
      displayName: 'Visa ****1234',
      isDefault: true,
      cardLast4: '1234',
      cardBrand: 'Visa',
      expiryDate: DateTime(2026, 12, 31),
    ),
    PaymentMethod(
      id: 'pm2',
      type: PaymentType.card,
      displayName: 'Mastercard ****5678',
      isDefault: false,
      cardLast4: '5678',
      cardBrand: 'Mastercard',
      expiryDate: DateTime(2025, 8, 31),
    ),
    PaymentMethod(
      id: 'pm3',
      type: PaymentType.bankAccount,
      displayName: 'Bank Account ****9012',
      isDefault: false,
    ),
  ];

  static List<PaymentTransaction> mockTransactions = [
    PaymentTransaction(
      id: 'tx1',
      taskId: 't1',
      taskTitle: 'Help moving furniture to new apartment',
      amount: 250.0,
      type: TransactionType.payment,
      status: TransactionStatus.completed,
      date: DateTime.now().subtract(const Duration(days: 2)),
      paymentMethodId: 'pm1',
      description: 'Task payment received',
    ),
    PaymentTransaction(
      id: 'tx2',
      taskId: 't3',
      taskTitle: 'Assemble IKEA furniture',
      amount: 120.0,
      type: TransactionType.payment,
      status: TransactionStatus.completed,
      date: DateTime.now().subtract(const Duration(days: 5)),
      paymentMethodId: 'pm1',
      description: 'Task payment received',
    ),
    PaymentTransaction(
      id: 'tx3',
      taskId: 't2',
      taskTitle: 'Deep cleaning for 3-bedroom house',
      amount: 180.0,
      type: TransactionType.payment,
      status: TransactionStatus.pending,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      paymentMethodId: 'pm2',
      description: 'Payment processing',
    ),
    PaymentTransaction(
      id: 'tx4',
      taskId: 't5',
      taskTitle: 'Lawn mowing and garden maintenance',
      amount: 80.0,
      type: TransactionType.withdrawal,
      status: TransactionStatus.completed,
      date: DateTime.now().subtract(const Duration(days: 10)),
      description: 'Withdrawn to bank account',
    ),
  ];

  static NotificationSettings mockNotificationSettings = const NotificationSettings(
    taskAlerts: true,
    messages: true,
    offers: true,
    taskReminders: true,
    promotions: false,
    emailNotifications: true,
    pushNotifications: true,
  );

  // Profile Methods
  Future<UserProfile> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockUserProfile;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    mockUserProfile = profile;
  }

  Future<NotificationSettings> getNotificationSettings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return mockNotificationSettings;
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 300));
    mockNotificationSettings = settings;
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockPaymentMethods;
  }

  Future<void> addPaymentMethod(PaymentMethod method) async {
    await Future.delayed(const Duration(milliseconds: 400));
    mockPaymentMethods.add(method);
  }

  Future<void> removePaymentMethod(String methodId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    mockPaymentMethods.removeWhere((m) => m.id == methodId);
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    mockPaymentMethods = mockPaymentMethods.map((m) {
      return m.copyWith(isDefault: m.id == methodId);
    }).toList();
  }

  Future<List<PaymentTransaction>> getPaymentHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockTransactions..sort((a, b) => b.date.compareTo(a.date));
  }

  // Questions Data
  static List<Question> mockQuestions = [
    Question(
      id: 'q1',
      taskId: 't1',
      userId: '3',
      userName: 'Sean K.',
      userImage: 'https://i.pravatar.cc/150?img=33',
      question: 'Have you lost any bits ???\n\nCan I get a picture of the bed and build so far please\n\nRegards Sean.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 23)),
    ),
    Question(
      id: 'q2',
      taskId: 't1',
      userId: '1',
      userName: 'Gareth R.',
      userImage: 'https://i.pravatar.cc/150?img=12',
      question: 'Hi. Can you add photos of the state of the bed at the moment please?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
    ),
    Question(
      id: 'q3',
      taskId: 't1',
      userId: '4',
      userName: 'Syed Waseem A.',
      question: 'Can I have pictures or design codes please',
      timestamp: DateTime.now().subtract(const Duration(minutes: 13)),
    ),
    // Questions for Task t2
    Question(
      id: 'q4',
      taskId: 't2',
      userId: '6',
      userName: 'Lisa M.',
      userImage: 'https://i.pravatar.cc/150?img=45',
      question: 'Is it a front loader or top loader?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Question(
      id: 'q5',
      taskId: 't2',
      userId: '1', // Current user
      userName: 'John Doe',
      userImage: 'https://i.pravatar.cc/150?img=12',
      question: 'It is a front loader Samsung BubbleWash.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
    ),
    // Questions for Task t3
    Question(
      id: 'q6',
      taskId: 't3',
      userId: '5',
      userName: 'Reiss H.',
      userImage: 'https://i.pravatar.cc/150?img=51',
      question: 'How wide are the stairs? Will the sofa fit?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  // Question Methods
  Future<List<Question>> getQuestions(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockQuestions
        .where((q) => q.taskId == taskId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> askQuestion(String taskId, String questionText) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newQuestion = Question(
      id: 'q${mockQuestions.length + 1}',
      taskId: taskId,
      userId: '1', // Current user
      userName: 'John Doe',
      userImage: 'https://i.pravatar.cc/150?img=12',
      question: questionText,
      timestamp: DateTime.now(),
    );
    mockQuestions.add(newQuestion);
  }

  // Categories Data
  static final List<Category> mockCategories = [
    const Category(id: 'all', slug: 'all', name: 'All', iconName: 'apps-outline', tier: 'artisanal', verificationLevel: 'basic'),
    const Category(id: 'cleaning', slug: 'cleaning', name: 'Cleaning', iconName: 'brush', tier: 'artisanal', verificationLevel: 'basic'),
    const Category(id: 'handyman', slug: 'handyman', name: 'Handyman', iconName: 'hammer-outline', tier: 'artisanal', verificationLevel: 'trade'),
    const Category(id: 'removals', slug: 'removals', name: 'Removals', iconName: 'cube-outline', tier: 'artisanal', verificationLevel: 'basic'),
    const Category(id: 'gardening', slug: 'gardening', name: 'Gardening', iconName: 'leaf', tier: 'artisanal', verificationLevel: 'basic'),
    const Category(id: 'painting', slug: 'painting', name: 'Painting', iconName: 'color-palette-outline', tier: 'artisanal', verificationLevel: 'basic'),
    const Category(id: 'assembly', slug: 'assembly', name: 'Assembly', iconName: 'construct', tier: 'artisanal', verificationLevel: 'trade'),
    const Category(id: 'plumbing', slug: 'plumbing', name: 'Plumbing', iconName: 'construct', tier: 'artisanal', verificationLevel: 'trade'),
    const Category(id: 'electrical', slug: 'electrical', name: 'Electrical', iconName: 'flash-outline', tier: 'professional', verificationLevel: 'pro'),
    const Category(id: 'delivery', slug: 'delivery', name: 'Delivery', iconName: 'cube-outline', tier: 'artisanal', verificationLevel: 'basic'),
    const Category(id: 'photography', slug: 'photography', name: 'Photography', iconName: 'camera', tier: 'artisanal', verificationLevel: 'basic'),
    const Category(id: 'pet-care', slug: 'pet-care', name: 'Pet Care', iconName: 'help-buoy-outline', tier: 'artisanal', verificationLevel: 'basic'),
    const Category(id: 'admin', slug: 'admin', name: 'Admin', iconName: 'file-tray-stacked-outline', tier: 'professional', verificationLevel: 'pro'),
  ];

  // Search History Data
  static List<SearchHistory> mockSearchHistory = [
    SearchHistory(
      id: 'sh1',
      query: 'Lawn care',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    SearchHistory(
      id: 'sh2',
      query: 'House cleaning',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    SearchHistory(
      id: 'sh3',
      query: 'Removalists',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SearchHistory(
      id: 'sh4',
      query: 'Photography',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // Category Methods
  Future<List<Category>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return mockCategories;
  }

  // Search History Methods
  Future<List<SearchHistory>> getSearchHistory() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return mockSearchHistory..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addSearchHistory(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Remove duplicates
    mockSearchHistory.removeWhere((item) => item.query.toLowerCase() == query.toLowerCase());
    // Add new history item
    mockSearchHistory.add(SearchHistory(
      id: 'sh${mockSearchHistory.length + 1}',
      query: query,
      timestamp: DateTime.now(),
    ));
    // Keep only latest 10
    if (mockSearchHistory.length > 10) {
      mockSearchHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      mockSearchHistory = mockSearchHistory.take(10).toList();
    }
  }

  Future<void> clearSearchHistory() async {
    await Future.delayed(const Duration(milliseconds: 100));
    mockSearchHistory.clear();
  }

  // Search Suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    final suggestions = <String>[];
    
    // Add matching categories
    for (var category in mockCategories) {
      if (category.name.toLowerCase().contains(lowerQuery) && category.id != 'all') {
        suggestions.add('${category.name} in ${category.name}');
      }
    }
    
    // Add some common task-related suggestions
    final commonSuggestions = [
      'Clean apartment',
      'Clean house',
      'Cleaner needed',
      'Lawn mowing',
      'Lawn care',
      'Gardening services',
      'Painting room',
      'Paint house',
      'Handyman services',
      'Furniture assembly',
      'Move house',
      'Removalist needed',
      'Plumber emergency',
      'Electrician needed',
      'Photography session',
      'Pet sitting',
      'Dog walking',
    ];
    
    for (var suggestion in commonSuggestions) {
      if (suggestion.toLowerCase().contains(lowerQuery)) {
        suggestions.add(suggestion);
      }
    }
    
    return suggestions.take(5).toList();
  }
}
